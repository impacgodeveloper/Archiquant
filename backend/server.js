require("dotenv").config();
const express    = require("express");
const multer     = require("multer");
const cors       = require("cors");
const path       = require("path");
const fs         = require("fs");
const bcrypt     = require("bcryptjs");
const jwt        = require("jsonwebtoken");
const PDFDocument = require("pdfkit");
const ExcelJS    = require("exceljs");
const { runOCR } = require("./services/easyocrService");
const supabase   = require("./config/supabase");

const app = express();
app.use(cors());
app.use(express.json());

// ── OCR format normalizer (handles both old list-format and new map-format) ──
function normalizeOCR(ocr) {
  // zones: new = {ZONE1: {...}}, old = [{zone_id, name, size, area_sqft}]
  const rawZones = ocr.zones || [];
  const zones = Array.isArray(rawZones)
    ? rawZones
    : Object.values(rawZones).map(z => ({
        zone_id:   z.id,
        name:      z.label || 'UNKNOWN',
        area_sqft: z.area_sqft || 0,
        size:      { length_ft: z.length_ft, width_ft: z.width_ft },
      }));

  // internal/external walls: new = {iw1:{thickness_in,height_ft}}, old = [{thickness_inch,height_ft,count}]
  let internal = [], external = [];
  if (ocr.internal_walls && !Array.isArray(ocr.internal_walls)) {
    // new format — group by thickness+height to get counts
    const groups = {};
    Object.values(ocr.internal_walls).forEach(w => {
      const key = `${w.thickness_in}-${w.height_ft}`;
      groups[key] = groups[key] || { thickness_inch: w.thickness_in, height_ft: w.height_ft, count: 0 };
      groups[key].count += Math.max(1, parseInt(w.nos) || 1);
    });
    internal = Object.values(groups);
  } else {
    internal = ocr.walls?.internal || [];
  }
  if (ocr.external_walls && !Array.isArray(ocr.external_walls)) {
    const groups = {};
    Object.values(ocr.external_walls).forEach(w => {
      const key = `${w.thickness_in}-${w.height_ft}`;
      groups[key] = groups[key] || { thickness_inch: w.thickness_in, height_ft: w.height_ft, count: 0 };
      groups[key].count += Math.max(1, parseInt(w.nos) || 1);
    });
    external = Object.values(groups);
  } else {
    external = ocr.walls?.external || [];
  }

  // doors/windows: new = {d1:{width_ft,height_ft}}, old = [{size_ft:{width,height},count}]
  let doors = [], windows = [];
  if (ocr.doors && !Array.isArray(ocr.doors)) {
    const groups = {};
    Object.values(ocr.doors).forEach(d => {
      const key = `${d.width_ft}x${d.height_ft}`;
      groups[key] = groups[key] || { size_ft: { width: d.width_ft, height: d.height_ft }, count: 0 };
      groups[key].count += Math.max(1, parseInt(d.nos) || 1);
    });
    doors = Object.values(groups);
  } else {
    doors = ocr.openings?.doors || [];
  }
  if (ocr.windows && !Array.isArray(ocr.windows)) {
    const groups = {};
    Object.values(ocr.windows).forEach(w => {
      const key = `${w.width_ft}x${w.height_ft}`;
      groups[key] = groups[key] || { size_ft: { width: w.width_ft, height: w.height_ft }, count: 0 };
      groups[key].count += Math.max(1, parseInt(w.nos) || 1);
    });
    windows = Object.values(groups);
  } else {
    windows = ocr.openings?.windows || [];
  }

  return { zones, internal, external, doors, windows };
}

// ── Merge user edits (Save Room) into the OCR object ─────────────────────────
// When a plan has edited_components, the user's edited walls/doors/windows
// become the source of truth for costing/takeoff. We keep the original zones
// (zone sizes aren't edited in the UI) and override walls + openings from the
// edits. Returns an OCR-shaped object the existing calc logic understands.
function applyEdits(rawOcr, edited) {
  if (!edited || typeof edited !== "object") return rawOcr;
  const ocr = { ...(rawOcr || {}) };

  const internal_walls = {}, external_walls = {}, doors = {}, windows = {};
  let iw = 0, ew = 0, dn = 0, wn = 0;

  (edited.walls || []).forEach((x) => {
    const comp = String(x.component || "").toLowerCase();
    const thick = Number(x.w) || 0;
    const isExt = comp.startsWith("ew") || (!comp.startsWith("iw") && thick >= 9);
    // Guard against implausibly thin saved thickness (e.g. 1") which would
    // mis-classify a 9" brick wall. A real wall is >= 3"; otherwise use the
    // standard default for its type (external 9", internal 4").
    const safeThick = thick >= 3 ? thick : (isExt ? 9 : 4);
    const base = {
      height_ft: Number(x.h) || 10,
      length_ft: Number(x.l) || 0,
      thickness_in: safeThick,
      position: x.position || "unknown",
      nos: Math.max(1, parseInt(x.nos) || 1),
    };
    if (isExt) {
      ew += 1;
      external_walls[`ew${ew}`] = { id: `ew${ew}`, ...base,
        connected: { doors: [], windows: [], internal_walls: [] } };
    } else {
      iw += 1;
      internal_walls[`iw${iw}`] = { id: `iw${iw}`, ...base,
        connected: { doors: [], windows: [] }, connects_external: [] };
    }
  });

  (edited.doors || []).forEach((x) => {
    dn += 1;
    doors[`d${dn}`] = { id: `d${dn}`, width_ft: Number(x.l) || 3,
      height_ft: Number(x.h) || 7, on_wall: null,
      thickness_in: Number(x.w) >= 3 ? Number(x.w) : 0,
      nos: Math.max(1, parseInt(x.nos) || 1) };
  });
  (edited.windows || []).forEach((x) => {
    wn += 1;
    windows[`w${wn}`] = { id: `w${wn}`, width_ft: Number(x.l) || 4,
      height_ft: Number(x.h) || 4, on_wall: null,
      thickness_in: Number(x.w) >= 3 ? Number(x.w) : 0,
      nos: Math.max(1, parseInt(x.nos) || 1) };
  });

  // Only override if the user actually has edited walls/openings
  if (Object.keys(internal_walls).length || Object.keys(external_walls).length) {
    ocr.internal_walls = internal_walls;
    ocr.external_walls = external_walls;
  }
  if (Object.keys(doors).length)   ocr.doors   = doors;
  if (Object.keys(windows).length) ocr.windows = windows;
  return ocr;
}

if (!fs.existsSync("uploads")) fs.mkdirSync("uploads");

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "uploads"),
  filename:    (req, file, cb) =>
      cb(null, Date.now() + "-" + file.originalname),
});
const upload = multer({ storage });

async function withCompany(company_id) {
  await supabase.rpc("set_config", {
    setting: "app.current_company_id",
    value:   company_id,
  });
}

function authMiddleware(req, res, next) {
  const token =
    req.headers.authorization?.split(" ")[1] ||
    req.query.token;
  if (!token) return res.status(401).json({ error: "No token" });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: "Invalid token" });
  }
}

// ═══════════════════════════════════════════════════════════
// AUTH
// ═══════════════════════════════════════════════════════════

app.post("/auth/register", async (req, res) => {
  const {
    company_name, company_slug, email,
    password, plan = "starter", phone = "",
  } = req.body;

  const planLimits = {
    starter:      { max_projects: 3,      max_users: 4      },
    professional: { max_projects: 999,    max_users: 6      },
    enterprise:   { max_projects: 999999, max_users: 999999 },
  };
  const limits = planLimits[plan] || planLimits.starter;

  try {
    if (!company_name || !company_slug || !email || !password) {
      return res.status(400).json({ error: "Please fill all required fields" });
    }

    const { data: existingCompany } = await supabase
      .from("companies").select("id").eq("slug", company_slug).single();
    if (existingCompany) {
      return res.status(400).json({
        error: "This company ID is already taken. Please choose another."
      });
    }

    const { data: existingUser } = await supabase
      .from("users").select("id").eq("email", email).single();
    if (existingUser) {
      return res.status(400).json({ error: "Email already registered" });
    }

    const { data: company, error: companyErr } = await supabase
      .from("companies")
      .insert([{
        name: company_name, slug: company_slug, plan,
        max_projects: limits.max_projects,
        max_users:    limits.max_users,
        plan_expires_at: new Date(
          Date.now() + 14 * 24 * 60 * 60 * 1000
        ).toISOString(),
      }])
      .select().single();
    if (companyErr) return res.status(400).json({ error: companyErr.message });

    const password_hash = await bcrypt.hash(password, 10);
    const { data: user, error: userErr } = await supabase
      .from("users")
      .insert([{
        company_id: company.id, email, password_hash,
        role: "admin", active: true,
        phone: phone || "", full_name: email.split("@")[0],
      }])
      .select().single();

    if (userErr) {
      await supabase.from("companies").delete().eq("id", company.id);
      return res.status(400).json({ error: userErr.message });
    }

    await supabase.from("company_settings").insert([{ company_id: company.id }]);

    await supabase.from("material_configs").insert([{
      company_id: company.id,
      name: "Standard Red Brick",
      brick_length_m: 0.19, brick_width_m: 0.09, brick_height_m: 0.09,
      mortar_ratio_cement: 1.0, mortar_ratio_sand: 5.0, is_default: true,
    }]);

    await supabase.from("formula_definitions").insert([
      { company_id: company.id, name: "brick_face_area",            expression: "0.75 * 0.25", description: "Standard brick face area in sqft (9×3 inch)",       variables: [], output_unit: "sqft",       is_system_default: true, active: true },
      { company_id: company.id, name: "buffer_percentage",          expression: "5",           description: "Wastage buffer percentage for all materials (matches BOQ)", variables: [], output_unit: "percentage", is_system_default: true, active: true },
      { company_id: company.id, name: "red_brick_thickness",        expression: "9",           description: "Walls with this thickness (inches) use Red Brick",    variables: [], output_unit: "inches",     is_system_default: true, active: true },
      { company_id: company.id, name: "white_cement_thickness",     expression: "4,6",         description: "Walls with these thicknesses use White Cement Block",  variables: [], output_unit: "inches",     is_system_default: true, active: true },
      { company_id: company.id, name: "thickness_multiplier_4inch", expression: "1.0",         description: "4 inch wall thickness multiplier",                    variables: [], output_unit: "multiplier", is_system_default: true, active: true },
      { company_id: company.id, name: "thickness_multiplier_6inch", expression: "1.5",         description: "6 inch wall thickness multiplier",                    variables: [], output_unit: "multiplier", is_system_default: true, active: true },
      { company_id: company.id, name: "thickness_multiplier_8inch", expression: "2.0",         description: "8 inch wall thickness multiplier",                    variables: [], output_unit: "multiplier", is_system_default: true, active: true },
      { company_id: company.id, name: "thickness_multiplier_9inch", expression: "2.25",        description: "9 inch wall thickness multiplier",                    variables: [], output_unit: "multiplier", is_system_default: true, active: true },
    ]);

    const token = jwt.sign(
      { user_id: user.id, company_id: company.id, role: user.role, plan: company.plan },
      process.env.JWT_SECRET, { expiresIn: "7d" }
    );

    return res.status(201).json({
      token,
      user:    { id: user.id, email: user.email, role: user.role, full_name: user.full_name, phone: user.phone },
      company: { id: company.id, name: company.name, slug: company.slug, plan: company.plan, max_projects: company.max_projects, max_users: company.max_users },
    });
  } catch (err) {
    console.error("REGISTER ERROR:", err);
    return res.status(500).json({ error: err.message || "Internal server error" });
  }
});

app.post("/auth/login", async (req, res) => {
  const { email, password, company_slug } = req.body;
  try {
    const { data: company } = await supabase
      .from("companies").select("id").eq("slug", company_slug).single();
    if (!company) return res.status(404).json({ error: "Company not found" });

    const { data: user } = await supabase
      .from("users").select("*")
      .eq("company_id", company.id).eq("email", email).single();
    if (!user) return res.status(401).json({ error: "Invalid credentials" });

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) return res.status(401).json({ error: "Invalid credentials" });

    const token = jwt.sign(
      { user_id: user.id, company_id: company.id, role: user.role },
      process.env.JWT_SECRET, { expiresIn: "7d" }
    );
    res.json({ token, user: { ...user, password_hash: undefined } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════
// PROFILE
// ═══════════════════════════════════════════════════════════

app.get("/profile", authMiddleware, async (req, res) => {
  const { user_id, company_id } = req.user;
  await withCompany(company_id);
  const { data, error } = await supabase
    .from("users")
    .select("id, email, role, full_name, phone, active, created_at")
    .eq("id", user_id).single();
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

app.patch("/profile", authMiddleware, async (req, res) => {
  const { user_id, company_id } = req.user;
  await withCompany(company_id);
  const { full_name, phone } = req.body;
  const { data, error } = await supabase
    .from("users")
    .update({ full_name, phone, updated_at: new Date() })
    .eq("id", user_id).eq("company_id", company_id)
    .select("id, email, role, full_name, phone").single();
  if (error) return res.status(500).json({ error: error.message });
  res.json({ success: true, user: data });
});

// ═══════════════════════════════════════════════════════════
// PROJECTS
// ═══════════════════════════════════════════════════════════

app.get("/projects", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { data, error } = await supabase
    .from("projects").select("*").eq("company_id", company_id)
    .order("created_at", { ascending: false });
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

app.post("/projects", authMiddleware, async (req, res) => {
  const { company_id, user_id } = req.user;
  await withCompany(company_id);
  const { name, description } = req.body;
  const { data, error } = await supabase
    .from("projects")
    .insert([{ company_id, owner_id: user_id, name, description }])
    .select().single();
  if (error) return res.status(500).json({ error: error.message });
  res.status(201).json(data);
});

app.get("/projects/:id", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { data, error } = await supabase
    .from("projects").select("*")
    .eq("id", req.params.id).eq("company_id", company_id).single();
  if (error) return res.status(404).json({ error: "Not found" });
  res.json(data);
});

// ═══════════════════════════════════════════════════════════
// FLOOR PLANS + OCR
// ═══════════════════════════════════════════════════════════

app.post(
  "/projects/:project_id/floor-plans",
  authMiddleware, upload.single("file"),
  async (req, res) => {
    const { company_id } = req.user;
    const { project_id } = req.params;
    try {
      const filePath = path.resolve(req.file.path);
      const fileType = req.file.mimetype;
      await withCompany(company_id);

      const { data: plan, error: planErr } = await supabase
        .from("floor_plans")
        .insert([{ company_id, project_id, file_url: req.file.path, file_type: fileType, ocr_status: "processing" }])
        .select().single();
      if (planErr) return res.status(500).json({ error: planErr.message });

      const ocrResult = await runOCR(filePath);
      await supabase.from("floor_plans")
        .update({ ocr_status: "done", raw_ocr_data: ocrResult })
        .eq("id", plan.id);

      // ── Build structural elements with length_m ────
      const { internal: intWalls, external: extWalls, doors: ocrDoors, windows: ocrWindows } = normalizeOCR(ocrResult);
      const totalAreaSqft = ocrResult.summary?.total_area_sqft || 0;
      const totalAreaSqM  = totalAreaSqft * 0.0929;
      const perimeterM    = 4 * Math.sqrt(totalAreaSqM);

      const extCount   = extWalls.reduce((s, w) => s + (w.count || 1), 0);
      const intCount   = intWalls.reduce((s, w) => s + (w.count || 1), 0);
      const avgExtLenM = extCount > 0 ? perimeterM / extCount : 3.0;
      const avgIntLenM = totalAreaSqM > 0 ? (totalAreaSqM / (intCount || 1)) / 3.0 : 2.5;

      const elements = [];

      extWalls.forEach((w) => {
        elements.push({
          company_id, floor_plan_id: plan.id, element_type: "wall",
          length_m:    parseFloat(avgExtLenM.toFixed(3)),
          thickness_m: (w.thickness_inch || 9) * 0.0254,
          height_m:    (w.height_ft || 10) * 0.3048,
          metadata:    { type: "external", count: w.count || 1 },
        });
      });

      intWalls.forEach((w) => {
        elements.push({
          company_id, floor_plan_id: plan.id, element_type: "wall",
          length_m:    parseFloat(avgIntLenM.toFixed(3)),
          thickness_m: (w.thickness_inch || 4) * 0.0254,
          height_m:    (w.height_ft || 10) * 0.3048,
          metadata:    { type: "internal", count: w.count || 1 },
        });
      });

      ocrDoors.forEach((d) => {
        elements.push({
          company_id, floor_plan_id: plan.id, element_type: "door",
          width_m:  (d.size_ft?.width  || 3) * 0.3048,
          height_m: (d.size_ft?.height || 7) * 0.3048,
          metadata: { count: d.count || 1 },
        });
      });

      ocrWindows.forEach((w) => {
        elements.push({
          company_id, floor_plan_id: plan.id, element_type: "window",
          width_m:  (w.size_ft?.width  || 4) * 0.3048,
          height_m: (w.size_ft?.height || 4) * 0.3048,
          metadata: { count: w.count || 1 },
        });
      });

      if (elements.length > 0) {
        await supabase.from("structural_elements").insert(elements);
      }

      res.json({ success: true, plan, data: ocrResult });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  }
);

// ═══════════════════════════════════════════════════════════
// SAVE ROOM COMPONENTS (edited on the results page)
//   - stores the full edited room as JSON (floor_plans.edited_components)
//   - AND replaces normalized rows in structural_elements
// ═══════════════════════════════════════════════════════════
app.put("/projects/:project_id/components", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  const { project_id } = req.params;
  const components = (req.body && req.body.components) || {};
  await withCompany(company_id);

  try {
    // latest done floor plan for this project
    const { data: plans } = await supabase
      .from("floor_plans").select("id")
      .eq("project_id", project_id).eq("company_id", company_id)
      .eq("ocr_status", "done")
      .order("created_at", { ascending: false }).limit(1);

    if (!plans?.length) {
      return res.status(404).json({ error: "No floor plan found. Upload a plan first." });
    }
    const planId = plans[0].id;

    // 1) JSON blob — exact editor state for fast reload
    await supabase.from("floor_plans")
      .update({ edited_components: components })
      .eq("id", planId).eq("company_id", company_id);

    // 2) Normalized rows — wipe & rebuild for this plan
    await supabase.from("structural_elements")
      .delete().eq("floor_plan_id", planId).eq("company_id", company_id);

    const FT = 0.3048, IN = 0.0254;
    const rows = [];

    const addDim = (type, list) => (list || []).forEach((c) => {
      rows.push({
        company_id, floor_plan_id: planId, element_type: type,
        length_m:    c.l != null ? parseFloat((c.l * FT).toFixed(4)) : null,
        height_m:    c.h != null ? parseFloat((c.h * FT).toFixed(4)) : null,
        thickness_m: c.w != null ? parseFloat((c.w * IN).toFixed(4)) : null,
        metadata: {
          component: c.component ?? null, material: c.material ?? null,
          position: c.position ?? null, room: c.room ?? null,
          l_ft: c.l ?? null, h_ft: c.h ?? null, w_in: c.w ?? null,
        },
      });
    });
    const addPoint = (type, list) => (list || []).forEach((c) => {
      rows.push({
        company_id, floor_plan_id: planId, element_type: type,
        metadata: { component: c.component ?? null, type: c.type ?? null, room: c.room ?? null },
      });
    });

    addDim("wall",      components.walls);
    addDim("door",      components.doors);
    addDim("window",    components.windows);
    addDim("ceiling",   components.ceiling);
    addDim("flooring",  components.flooring);
    addDim("finish",    components.finishes);
    addDim("furniture", components.furniture);
    addDim("other",     components.others);
    addPoint("electrical", components.electrical);
    addPoint("plumbing",   components.plumbing);

    if (rows.length) {
      const { error: insErr } = await supabase.from("structural_elements").insert(rows);
      if (insErr) return res.status(500).json({ success: false, error: insErr.message });
    }

    res.json({ success: true, floor_plan_id: planId, saved: rows.length });
  } catch (err) {
    console.error("Save components error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════
// BRICK CALCULATION
// ═══════════════════════════════════════════════════════════

app.post("/projects/:project_id/calculate", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  const { project_id } = req.params;
  await withCompany(company_id);

  try {
    const { data: plans } = await supabase
      .from("floor_plans").select("id, raw_ocr_data, edited_components")
      .eq("project_id", project_id).eq("company_id", company_id)
      .eq("ocr_status", "done").order("created_at", { ascending: false }).limit(1);

    if (!plans?.length) {
      return res.status(404).json({ error: "No OCR data found. Please upload a floor plan first." });
    }

    const { data: formulas } = await supabase
      .from("formula_definitions").select("name, expression")
      .eq("company_id", company_id).eq("active", true);

    const fMap = {};
    (formulas || []).forEach((f) => { fMap[f.name] = f.expression; });

    const BRICK_FACE_SQFT     = parseFloat(eval(fMap["brick_face_area"] || "0.75 * 0.25"));
    const BUFFER_PCT          = parseFloat(fMap["buffer_percentage"] || "5");
    const BRICKS_PER_M3       = parseFloat(fMap["bricks_per_m3"] || "500");  // BOQ master constant
    const redBrickThicknesses = (fMap["red_brick_thickness"] || "9").split(",").map(Number);

    const { data: compSettings } = await supabase
      .from("company_settings")
      .select("default_cement_mix, default_plaster_thickness, default_sand_unit, wastage_pct")
      .eq("company_id", company_id).single();

    const defaultMix       = compSettings?.default_cement_mix        || "1:4";
    const defaultThickness = compSettings?.default_plaster_thickness || "18mm";
    const defaultSandUnit  = compSettings?.default_sand_unit         || "tons";

    const thicknessMultiplier = (inch) => {
      const key = `thickness_multiplier_${inch}inch`;
      if (fMap[key]) return parseFloat(fMap[key]);
      if (inch <= 4) return 1.0;
      if (inch <= 6) return 1.5;
      if (inch <= 8) return 2.0;
      return 2.25;
    };

    const thicknessInFeet = (inch) => {
      if (inch === 9) return 0.75;
      if (inch === 6) return 0.50;
      if (inch === 4) return 0.33;
      if (inch === 8) return 0.67;
      return inch / 12;
    };

    const ocr     = applyEdits(plans[0].raw_ocr_data, plans[0].edited_components);
    const summary = ocr.summary || {};
    const { zones, internal, external, doors: ocrDoors, windows: ocrWindows } = normalizeOCR(ocr);

    const totalAreaSqft = summary.total_area_sqft || 0;
    const totalAreaSqM  = totalAreaSqft * 0.0929;
    const perimeterFt   = 4 * Math.sqrt(totalAreaSqM) * 3.281;

    // ── Per-wall detail with REAL lengths from the OCR ───────────────────
    // BOQ rule: never average — use each wall's actual L, B, H. The OCR now
    // returns length_ft per wall; we only fall back to an estimate if it's
    // genuinely missing.
    const extGroupCount = external.reduce((s, w) => s + (w.count || 1), 0) || 1;
    const intGroupCount = internal.reduce((s, w) => s + (w.count || 1), 0) || 1;
    const fallbackExtLen = perimeterFt / extGroupCount;
    const fallbackIntLen = totalAreaSqft > 0 ? (totalAreaSqft / intGroupCount) / 10 : 8;

    const detailWalls = (rawMap, grouped, type) => {
      const fb = type === "external" ? fallbackExtLen : fallbackIntLen;
      const defT = type === "external" ? 9 : 4;
      // New OCR format: dict keyed by id, each with its own length_ft
      if (rawMap && !Array.isArray(rawMap) && Object.keys(rawMap).length) {
        return Object.values(rawMap).map((w) => ({
          type,
          id:             w.id || "",
          length_ft:      (w.length_ft && w.length_ft > 0) ? w.length_ft : fb,
          height_ft:      w.height_ft || 10,
          thickness_inch: w.thickness_in || defT,
          nos:            Math.max(1, parseInt(w.nos) || 1),
        }));
      }
      // Old grouped format: expand counts, lengths unknown → fallback
      return (grouped || []).flatMap((w) =>
        Array.from({ length: w.count || 1 }, () => ({
          type,
          id:             "",
          length_ft:      fb,
          height_ft:      w.height_ft || 10,
          thickness_inch: w.thickness_inch || defT,
          nos:            1,
        })));
    };

    const extWalls = detailWalls(ocr.external_walls, external, "external");
    const intWalls = detailWalls(ocr.internal_walls, internal, "internal");

    const calcWallBricks = (wallList) => {
      return wallList.map((wall) => {
        const nos        = Math.max(1, parseInt(wall.nos) || 1);  // count of identical walls
        const L          = wall.length_ft;
        const H          = wall.height_ft || 10;
        const thick      = wall.thickness_inch || 9;
        const B          = thicknessInFeet(thick);
        const multiplier = thicknessMultiplier(thick);

        const wallFaceSqft    = L * H;
        const wallVolumeCuFt  = L * B * H * nos;
        const wallVolumeCuM   = wallVolumeCuFt * 0.0283168;
        // BOQ method: bricks = brickwork VOLUME (m³) × bricks-per-m³
        const bricksPerFace   = wallFaceSqft / BRICK_FACE_SQFT;   // kept for reference only
        const bricksRaw       = wallVolumeCuM * BRICKS_PER_M3;
        const bricksWithBuffer = Math.ceil(bricksRaw * (1 + BUFFER_PCT / 100));
        const brickType = redBrickThicknesses.includes(thick) ? "red_brick" : "white_cement";

        return {
          type:              wall.type,
          brick_type:        brickType,
          description:       `${wall.type === "external" ? "Ext" : "Int"} Wall ${thick}"`
                              + (wall.id ? ` (${wall.id})` : ""),
          thickness_inch:    thick,
          thickness_ft:      B,
          multiplier,
          L:                 parseFloat(L.toFixed(2)),
          H, nos,
          wall_face_sqft:    parseFloat(wallFaceSqft.toFixed(2)),
          wall_volume_cuft:  parseFloat(wallVolumeCuFt.toFixed(3)),
          wall_volume_cum:   parseFloat(wallVolumeCuM.toFixed(4)),
          bricks_per_face:   Math.ceil(bricksPerFace),
          bricks_raw:        Math.ceil(bricksRaw),
          bricks_with_10pct: bricksWithBuffer,
        };
      });
    };

    const allBreakdown = [
      ...calcWallBricks(extWalls),
      ...calcWallBricks(intWalls),
    ];

    // Wall-thickness lookup (id → inches) so each opening is deducted using
    // the thickness of the wall it sits on — exactly like the BOQ sheet.
    const wallThk = {};
    [ocr.internal_walls, ocr.external_walls].forEach((m) => {
      if (m && !Array.isArray(m)) {
        Object.values(m).forEach((w) => { wallThk[w.id] = w.thickness_in; });
      }
    });

    // Build openings with per-opening wall thickness (new format has on_wall);
    // old grouped format falls back to a 9" wall.
    const buildOpenings = (rawMap, grouped) => {
      if (rawMap && !Array.isArray(rawMap) && Object.keys(rawMap).length) {
        return Object.values(rawMap).map((o) => ({
          L: o.width_ft || 0, H: o.height_ft || 0,
          nos: Math.max(1, parseInt(o.nos) || 1),
          // prefer the opening's own thickness (editor W field); else the wall it sits on
          thick: (o.thickness_in && o.thickness_in >= 3) ? o.thickness_in : (wallThk[o.on_wall] || 9),
        }));
      }
      return (grouped || []).map((o) => ({
        L: o.size_ft?.width || 0, H: o.size_ft?.height || 0, nos: o.count || 1, thick: 9,
      }));
    };

    const doorOpenings   = buildOpenings(ocr.doors,   ocrDoors);
    const windowOpenings = buildOpenings(ocr.windows, ocrWindows);

    // Deduct openings by VOLUME (L × B × H), B = the wall's thickness → ×500/m³
    const calcOpeningDeduction = (openings) => {
      let totalDedBricks = 0, totalVolCuFt = 0;
      const items = [];
      for (const o of openings) {
        const B         = thicknessInFeet(o.thick);
        const volCuFt   = o.L * B * o.H * o.nos;
        const volCuM    = volCuFt * 0.0283168;
        const dedBricks = Math.ceil(volCuM * BRICKS_PER_M3);
        totalDedBricks += dedBricks;
        totalVolCuFt   += volCuFt;
        items.push({
          description: `${o.L}×${o.H}ft (${o.thick}")`, nos: o.nos,
          face_sqft: parseFloat((o.L * o.H * o.nos).toFixed(2)),
          volume_cuft: parseFloat(volCuFt.toFixed(3)),
          bricks_deducted: dedBricks,
        });
      }
      return { items, total_bricks: totalDedBricks, volume_cuft: parseFloat(totalVolCuFt.toFixed(3)) };
    };

    const windowDed = calcOpeningDeduction(windowOpenings);
    const doorDed   = calcOpeningDeduction(doorOpenings);
    const FT3_M3 = 0.0283168;

    // ── Volumes (BOQ Excel method) ─────────────────────────────
    const totalGrossVolumeCuFt = allBreakdown.reduce((s, w) => s + w.wall_volume_cuft, 0);
    const totalDedVolumeCuFt   = (windowDed.volume_cuft || 0) + (doorDed.volume_cuft || 0);
    const netVolumeCuFt        = Math.max(0, totalGrossVolumeCuFt - totalDedVolumeCuFt);
    const netVolumeCuM         = parseFloat((netVolumeCuFt * FT3_M3).toFixed(4));

    const redRows    = allBreakdown.filter((w) => w.brick_type === "red_brick");
    const whiteRows  = allBreakdown.filter((w) => w.brick_type === "white_cement");
    const redGrossVolCuFt   = redRows.reduce((s, w) => s + w.wall_volume_cuft, 0);
    const whiteGrossVolCuFt = whiteRows.reduce((s, w) => s + w.wall_volume_cuft, 0);
    const splitDenom        = (redGrossVolCuFt + whiteGrossVolCuFt) || 1;
    // split opening deductions between red/white by their share of wall volume
    const redDedVolCuFt   = totalDedVolumeCuFt * (redGrossVolCuFt   / splitDenom);
    const whiteDedVolCuFt = totalDedVolumeCuFt * (whiteGrossVolCuFt / splitDenom);
    const redNetVolCuM    = Math.max(0, redGrossVolCuFt   - redDedVolCuFt)   * FT3_M3;
    const whiteNetVolCuM  = Math.max(0, whiteGrossVolCuFt - whiteDedVolCuFt) * FT3_M3;

    // ── Bricks = volume (m³) × bricks/m³ × buffer  (matches BOQ Excel) ──
    const buf         = (1 + BUFFER_PCT / 100);
    const grossBricks = Math.round(totalGrossVolumeCuFt * FT3_M3 * BRICKS_PER_M3);
    const totalDed    = Math.round(totalDedVolumeCuFt   * FT3_M3 * BRICKS_PER_M3);
    const netBricks   = Math.max(0, Math.round(netVolumeCuM * BRICKS_PER_M3));
    const finalBricks = Math.ceil(netVolumeCuM * BRICKS_PER_M3 * buf);

    const redGross   = Math.round(redGrossVolCuFt   * FT3_M3 * BRICKS_PER_M3);
    const whiteGross = Math.round(whiteGrossVolCuFt * FT3_M3 * BRICKS_PER_M3);
    const redDed     = Math.round(redDedVolCuFt     * FT3_M3 * BRICKS_PER_M3);
    const whiteDed   = Math.round(whiteDedVolCuFt   * FT3_M3 * BRICKS_PER_M3);
    const redNet     = Math.max(0, redGross   - redDed);
    const whiteNet   = Math.max(0, whiteGross - whiteDed);
    const redFinal   = Math.ceil(redNetVolCuM   * BRICKS_PER_M3 * buf);
    const whiteFinal = Math.ceil(whiteNetVolCuM * BRICKS_PER_M3 * buf);

    const cementMasterData = {
      "1:3": { "12mm": 2.6, "18mm": 3.5 },
      "1:4": { "12mm": 2.0, "18mm": 2.7 },
      "1:5": { "12mm": 1.7, "18mm": 2.3 },
      "1:6": { "12mm": 1.5, "18mm": 2.0 },
    };
    const sandMasterData = {
      "1:3": { "cum": 1.25, "tons": 2.1 },
      "1:4": { "cum": 1.35, "tons": 2.2 },
      "1:5": { "cum": 1.40, "tons": 2.3 },
      "1:6": { "cum": 1.50, "tons": 2.5 },
    };

    const cementSandCalc = {};
    for (const mix of ["1:3", "1:4", "1:5", "1:6"]) {
      cementSandCalc[mix] = {
        mix,
        cement_bags_12mm: parseFloat((netVolumeCuM * cementMasterData[mix]["12mm"]).toFixed(2)),
        cement_bags_18mm: parseFloat((netVolumeCuM * cementMasterData[mix]["18mm"]).toFixed(2)),
        sand_cum:         parseFloat((netVolumeCuM * sandMasterData[mix]["cum"]).toFixed(3)),
        sand_tons:        parseFloat((netVolumeCuM * sandMasterData[mix]["tons"]).toFixed(3)),
      };
    }

    const cementBags = defaultThickness === "12mm"
      ? cementSandCalc[defaultMix].cement_bags_12mm
      : cementSandCalc[defaultMix].cement_bags_18mm;
    const sandCuM  = cementSandCalc[defaultMix].sand_cum;
    const sandTons = cementSandCalc[defaultMix].sand_tons;

    const wallCementSand = allBreakdown.map((w) => {
      const volCuM = w.wall_volume_cum;
      return {
        description:      w.description,
        thickness_inch:   w.thickness_inch,
        nos:              w.nos,
        volume_cuft:      w.wall_volume_cuft,
        volume_cum:       volCuM,
        cement_bags_12mm: parseFloat((volCuM * cementMasterData[defaultMix]["12mm"]).toFixed(2)),
        cement_bags_18mm: parseFloat((volCuM * cementMasterData[defaultMix]["18mm"]).toFixed(2)),
        sand_cum:         parseFloat((volCuM * sandMasterData[defaultMix]["cum"]).toFixed(3)),
        sand_tons:        parseFloat((volCuM * sandMasterData[defaultMix]["tons"]).toFixed(3)),
      };
    });

    const result = {
      project_id, floor_plan_id: plans[0].id, company_id,
      buffer_pct: BUFFER_PCT, brick_face_sqft: BRICK_FACE_SQFT,

      formulas_used: {
        brick_face_area: BRICK_FACE_SQFT, buffer_pct: BUFFER_PCT,
        red_brick_thickness: redBrickThicknesses,
        default_mix: defaultMix, default_thickness: defaultThickness,
        multipliers: {
          "4inch": thicknessMultiplier(4), "6inch": thicknessMultiplier(6),
          "8inch": thicknessMultiplier(8), "9inch": thicknessMultiplier(9),
        },
      },

      zone_summary: zones.map((z) => ({ name: z.label || z.name, zone_id: z.id || z.zone_id, area_sqft: z.area_sqft, size: z.size, length_ft: z.length_ft, width_ft: z.width_ft })),
      wall_breakdown: allBreakdown,

      deductions: {
        windows: windowDed, doors: doorDed,
        total_bricks_deducted: totalDed,
      },

      red_brick: {
        label: "Red Brick", walls: redRows,
        gross_bricks: Math.ceil(redGross), deducted: redDed,
        net_bricks: redNet, final_with_10pct: redFinal,
      },

      white_cement: {
        label: "White Cement Block", walls: whiteRows,
        gross_bricks: Math.ceil(whiteGross), deducted: whiteDed,
        net_bricks: whiteNet, final_with_10pct: whiteFinal,
      },

      grand_total: {
        gross_bricks: Math.ceil(grossBricks), total_deducted: totalDed,
        net_bricks: netBricks, final_bricks: finalBricks,
        red_bricks: redFinal, white_cement_blocks: whiteFinal,
        formula: `(${Math.ceil(grossBricks)} gross) - (${totalDed} openings) = ${netBricks} net + ${BUFFER_PCT}% = ${finalBricks} total`,
      },

      volume_summary: {
        gross_volume_cuft: parseFloat(totalGrossVolumeCuFt.toFixed(3)),
        deduction_cuft:    parseFloat(totalDedVolumeCuFt.toFixed(3)),
        net_volume_cuft:   parseFloat(netVolumeCuFt.toFixed(3)),
        net_volume_cum:    netVolumeCuM,
      },

      cement: {
        default_mix: defaultMix, default_thickness: defaultThickness,
        total_bags:  cementBags, all_mixes: cementSandCalc,
        per_wall:    wallCementSand,
        note: "Based on client Master Data — bags per m³ of brickwork",
      },

      sand: {
        default_mix: defaultMix, total_cum: sandCuM, total_tons: sandTons,
        all_mixes: Object.fromEntries(
          Object.entries(cementSandCalc).map(([k, v]) => [k, { sand_cum: v.sand_cum, sand_tons: v.sand_tons }])
        ),
        per_wall: wallCementSand,
        note: "Based on client Master Data — m³/tons per m³ of brickwork",
      },

      ocr_summary: summary,
    };

    // ── Save — keep ONE estimation per project, always the latest ────────
    // Update the existing row (so Review/Takeoff/PDF reflect the most recent
    // plan); insert only if none exists yet. Previously this skipped the
    // update, leaving Review stuck on the first plan's numbers.
    await withCompany(company_id);
    const estPayload = {
      total_volume_m3: netVolumeCuM,
      total_bricks:    finalBricks,
      total_cement_kg: parseFloat((cementBags * 50).toFixed(2)),
      total_sand_kg:   parseFloat((sandTons * 1000).toFixed(2)),
      formula_snapshot: result,
    };

    const { data: existingEst } = await supabase
      .from("material_estimations").select("id")
      .eq("project_id", project_id).eq("company_id", company_id)
      .order("created_at", { ascending: false }).limit(1);

    if (existingEst && existingEst.length > 0) {
      // refresh the latest estimation in place
      await supabase.from("material_estimations")
        .update(estPayload)
        .eq("id", existingEst[0].id);
      // remove any older duplicate rows so only one remains
      if (existingEst.length > 1) {
        const keep = existingEst[0].id;
        await supabase.from("material_estimations")
          .delete().eq("project_id", project_id).eq("company_id", company_id)
          .neq("id", keep);
      }
    } else {
      await supabase.from("material_estimations")
        .insert([{ company_id, project_id, ...estPayload }]);
    }

    // ── Always return result ──────────────────────────
    res.json({ success: true, ...result });

  } catch (err) {
    console.error("Calculation error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════
// MATERIAL CONFIGS
// ═══════════════════════════════════════════════════════════

app.get("/material-configs", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { data, error } = await supabase
    .from("material_configs").select("*").eq("company_id", company_id);
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

app.post("/material-configs", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { data, error } = await supabase
    .from("material_configs")
    .insert([{ company_id, ...req.body }]).select().single();
  if (error) return res.status(500).json({ error: error.message });
  res.status(201).json(data);
});

// ═══════════════════════════════════════════════════════════
// FORMULAS
// ═══════════════════════════════════════════════════════════

app.post("/formulas/seed", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  try {
    const { data: existing } = await supabase
      .from("formula_definitions").select("id")
      .eq("company_id", company_id).limit(1);

    if (existing?.length > 0) {
      return res.json({ success: true, message: "Formulas already exist for this company" });
    }

    const { data, error } = await supabase.from("formula_definitions").insert([
      { company_id, name: "brick_face_area",            expression: "0.75 * 0.25", description: "Standard brick face area in sqft (9×3 inch)",       variables: [], output_unit: "sqft",       is_system_default: true, active: true },
      { company_id, name: "buffer_percentage",          expression: "5",           description: "Wastage buffer percentage for all materials (matches BOQ)", variables: [], output_unit: "percentage", is_system_default: true, active: true },
      { company_id, name: "red_brick_thickness",        expression: "9",           description: "Walls with this thickness (inches) use Red Brick",    variables: [], output_unit: "inches",     is_system_default: true, active: true },
      { company_id, name: "white_cement_thickness",     expression: "4,6",         description: "Walls with these thicknesses use White Cement Block",  variables: [], output_unit: "inches",     is_system_default: true, active: true },
      { company_id, name: "thickness_multiplier_4inch", expression: "1.0",         description: "4 inch wall thickness multiplier",                    variables: [], output_unit: "multiplier", is_system_default: true, active: true },
      { company_id, name: "thickness_multiplier_6inch", expression: "1.5",         description: "6 inch wall thickness multiplier",                    variables: [], output_unit: "multiplier", is_system_default: true, active: true },
      { company_id, name: "thickness_multiplier_8inch", expression: "2.0",         description: "8 inch wall thickness multiplier",                    variables: [], output_unit: "multiplier", is_system_default: true, active: true },
      { company_id, name: "thickness_multiplier_9inch", expression: "2.25",        description: "9 inch wall thickness multiplier",                    variables: [], output_unit: "multiplier", is_system_default: true, active: true },
    ]).select();

    if (error) return res.status(500).json({ error: error.message });
    res.json({ success: true, message: `${data.length} formulas created`, formulas: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/formulas", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { data, error } = await supabase
    .from("formula_definitions").select("*")
    .eq("company_id", company_id).eq("active", true).order("name");
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

app.patch("/formulas/:id", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { expression, description } = req.body;
  const { data, error } = await supabase
    .from("formula_definitions")
    .update({ expression, description })
    .eq("id", req.params.id).eq("company_id", company_id)
    .select().single();
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

// ═══════════════════════════════════════════════════════════
// ESTIMATIONS
// ═══════════════════════════════════════════════════════════

app.get("/projects/:project_id/estimations", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { data, error } = await supabase
    .from("material_estimations").select("*, estimation_details(*)")
    .eq("project_id", req.params.project_id).eq("company_id", company_id);
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

app.post("/projects/:project_id/estimations", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { data, error } = await supabase
    .from("material_estimations")
    .insert([{ company_id, project_id: req.params.project_id, ...req.body }])
    .select().single();
  if (error) return res.status(500).json({ error: error.message });
  res.status(201).json(data);
});

// ═══════════════════════════════════════════════════════════
// COMPANY SETTINGS
// ═══════════════════════════════════════════════════════════

app.get("/settings", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { data, error } = await supabase
    .from("company_settings").select("*")
    .eq("company_id", company_id).single();
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

app.patch("/settings", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { data, error } = await supabase
    .from("company_settings")
    .update({ ...req.body, updated_at: new Date() })
    .eq("company_id", company_id).select().single();
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

// ═══════════════════════════════════════════════════════════
// TEAM MANAGEMENT
// ═══════════════════════════════════════════════════════════

app.get("/team", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { data, error } = await supabase
    .from("users")
    .select("id, email, role, full_name, phone, active, created_at")
    .eq("company_id", company_id).order("created_at", { ascending: true });
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

app.post("/team/invite", authMiddleware, async (req, res) => {
  const { company_id, role: callerRole } = req.user;
  if (callerRole !== "admin") {
    return res.status(403).json({ error: "Only admins can invite users" });
  }
  const { email, password, role = "sub_user", full_name = "", phone = "" } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: "Email and password are required" });
  }
  await withCompany(company_id);
  try {
    const { data: company } = await supabase
      .from("companies").select("max_users").eq("id", company_id).single();
    const { data: currentUsers } = await supabase
      .from("users").select("id").eq("company_id", company_id);

    if (company?.max_users && currentUsers?.length >= company.max_users) {
      return res.status(400).json({
        error: `User limit reached. Your plan allows ${company.max_users} users. Upgrade to add more.`
      });
    }

    const { data: existing } = await supabase
      .from("users").select("id").eq("company_id", company_id).eq("email", email).single();
    if (existing) {
      return res.status(400).json({ error: "A user with this email already exists in your company" });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const { data: user, error } = await supabase
      .from("users")
      .insert([{ company_id, email, password_hash, role, active: true, full_name: full_name || email.split("@")[0], phone }])
      .select("id, email, role, full_name, phone, active, created_at").single();

    if (error) return res.status(500).json({ error: error.message });
    res.status(201).json({ success: true, user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.patch("/team/:user_id/toggle", authMiddleware, async (req, res) => {
  const { company_id, role: callerRole, user_id: callerId } = req.user;
  if (callerRole !== "admin") return res.status(403).json({ error: "Only admins can manage users" });
  if (req.params.user_id === callerId) return res.status(400).json({ error: "You cannot deactivate yourself" });
  await withCompany(company_id);
  const { data: current } = await supabase
    .from("users").select("active").eq("id", req.params.user_id).eq("company_id", company_id).single();
  if (!current) return res.status(404).json({ error: "User not found" });
  const { data, error } = await supabase
    .from("users").update({ active: !current.active })
    .eq("id", req.params.user_id).eq("company_id", company_id)
    .select("id, email, role, active").single();
  if (error) return res.status(500).json({ error: error.message });
  res.json({ success: true, user: data });
});

app.delete("/team/:user_id", authMiddleware, async (req, res) => {
  const { company_id, role: callerRole, user_id: callerId } = req.user;
  if (callerRole !== "admin") return res.status(403).json({ error: "Only admins can delete users" });
  if (req.params.user_id === callerId) return res.status(400).json({ error: "You cannot delete yourself" });
  await withCompany(company_id);
  const { error } = await supabase
    .from("users").delete().eq("id", req.params.user_id).eq("company_id", company_id);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ success: true });
});

// ═══════════════════════════════════════════════════════════
// MASTER RATES
// ═══════════════════════════════════════════════════════════

app.post("/master-rates/seed", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  try {
    const { data: existing } = await supabase
      .from("master_rates").select("id").eq("company_id", company_id).limit(1);
    if (existing?.length > 0) {
      return res.json({ success: true, message: "Rates already exist for this company" });
    }
    const defaultRates = [
      { company_id, material: "Red Brick (9\")",          category: "Bricks",  rate: 8.20,   unit: "piece", gst_pct: 18, loading: 0.20, transport_km: 0, distance_km: 0, unloading: 0.47 },
      { company_id, material: "White Cement Block (6\")", category: "Bricks",  rate: 12.00,  unit: "piece", gst_pct: 18, loading: 0.20, transport_km: 0, distance_km: 0, unloading: 0.47 },
      { company_id, material: "White Cement Block (4\")", category: "Bricks",  rate: 10.00,  unit: "piece", gst_pct: 18, loading: 0.20, transport_km: 0, distance_km: 0, unloading: 0.47 },
      { company_id, material: "Cement (1:3 CM)",          category: "Cement",  rate: 380.00, unit: "bag",   gst_pct: 18, loading: 3.00, transport_km: 0, distance_km: 0, unloading: 1.50 },
      { company_id, material: "Cement (1:4 CM)",          category: "Cement",  rate: 380.00, unit: "bag",   gst_pct: 18, loading: 3.00, transport_km: 0, distance_km: 0, unloading: 1.50 },
      { company_id, material: "Cement (1:5 CM)",          category: "Cement",  rate: 380.00, unit: "bag",   gst_pct: 18, loading: 3.00, transport_km: 0, distance_km: 0, unloading: 1.50 },
      { company_id, material: "Cement (1:6 CM)",          category: "Cement",  rate: 380.00, unit: "bag",   gst_pct: 18, loading: 3.00, transport_km: 0, distance_km: 0, unloading: 1.50 },
      { company_id, material: "River Sand",               category: "Sand",    rate: 600.00, unit: "ton",   gst_pct: 5,  loading: 15.00, transport_km: 0, distance_km: 0, unloading: 0 },
      { company_id, material: "M-Sand",                   category: "Sand",    rate: 450.00, unit: "ton",   gst_pct: 5,  loading: 15.00, transport_km: 0, distance_km: 0, unloading: 0 },
      { company_id, material: "Mason (Skilled)",          category: "Labour",  rate: 800.00, unit: "day",   gst_pct: 0,  loading: 0, transport_km: 0, distance_km: 0, unloading: 0 },
      { company_id, material: "Helper (Unskilled)",       category: "Labour",  rate: 500.00, unit: "day",   gst_pct: 0,  loading: 0, transport_km: 0, distance_km: 0, unloading: 0 },
    ];
    const { data, error } = await supabase.from("master_rates").insert(defaultRates).select();
    if (error) return res.status(500).json({ error: error.message });
    res.json({ success: true, message: `${data.length} default rates created`, data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/master-rates", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { data, error } = await supabase
    .from("master_rates").select("*")
    .eq("company_id", company_id).eq("active", true)
    .order("category").order("material");
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

app.patch("/master-rates/:id", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { rate, gst_pct, loading, transport_km, distance_km, unloading, notes } = req.body;
  const { data, error } = await supabase
    .from("master_rates")
    .update({ rate, gst_pct, loading, transport_km, distance_km, unloading, notes, updated_at: new Date() })
    .eq("id", req.params.id).eq("company_id", company_id)
    .select().single();
  if (error) return res.status(500).json({ error: error.message });
  res.json({ success: true, data });
});

app.post("/master-rates", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { data, error } = await supabase
    .from("master_rates").insert([{ company_id, ...req.body }]).select().single();
  if (error) return res.status(500).json({ error: error.message });
  res.status(201).json({ success: true, data });
});

app.delete("/master-rates/:id", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  await withCompany(company_id);
  const { error } = await supabase
    .from("master_rates").delete()
    .eq("id", req.params.id).eq("company_id", company_id);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ success: true });
});

// ═══════════════════════════════════════════════════════════
// REVIEW & BUDGET
// ═══════════════════════════════════════════════════════════

app.get("/projects/:project_id/review", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  const { project_id } = req.params;
  await withCompany(company_id);

  try {
    const { data: estimations } = await supabase
      .from("material_estimations").select("*")
      .eq("project_id", project_id).eq("company_id", company_id)
      .order("created_at", { ascending: false }).limit(1);

    if (!estimations?.length) {
      return res.status(404).json({ error: "No estimation found. Please run Costing first." });
    }

    const { data: rates } = await supabase
      .from("master_rates").select("*")
      .eq("company_id", company_id).eq("active", true);

    if (!rates?.length) {
      return res.status(404).json({ error: "No master rates found. Please setup Master List first." });
    }

    const snap = estimations[0].formula_snapshot;

    const findRate = (category, keyword) =>
      rates.find(r => r.category === category && r.material.toLowerCase().includes(keyword.toLowerCase()));

    const costAtSite = (r) => {
      if (!r) return 0;
      const base      = parseFloat(r.rate)         || 0;
      const gst       = base * (parseFloat(r.gst_pct) || 0) / 100;
      const loading   = parseFloat(r.loading)      || 0;
      const transport = parseFloat(r.transport_km) || 0;
      const unloading = parseFloat(r.unloading)    || 0;
      return base + gst + loading + transport + unloading;
    };

    const redBricks   = snap?.red_brick?.final_with_10pct    || 0;
    const whiteBricks = snap?.white_cement?.final_with_10pct || 0;
    const cementBags  = snap?.cement?.total_bags             || 0;
    const sandTons    = snap?.sand?.total_tons               || 0;
    const volCuM      = snap?.volume_summary?.net_volume_cum || 0;

    const redRate    = findRate('Bricks', 'Red Brick');
    const whiteRate  = findRate('Bricks', 'White Cement');
    const cementRate = findRate('Cement', '1:4');
    const sandRate   = findRate('Sand',   'River Sand');
    const masonRate  = findRate('Labour', 'Mason');
    const helperRate = findRate('Labour', 'Helper');

    const redCostPerUnit   = costAtSite(redRate);
    const whiteCostPerUnit = costAtSite(whiteRate);
    const cementPerBag     = costAtSite(cementRate);
    const sandPerTon       = costAtSite(sandRate);

    const redBrickCost    = redBricks   * redCostPerUnit;
    const whiteBrickCost  = whiteBricks * whiteCostPerUnit;
    const totalBrickCost  = redBrickCost + whiteBrickCost;
    const totalCementCost = cementBags  * cementPerBag;
    const totalSandCost   = sandTons    * sandPerTon;

    const masonDays       = Math.ceil(volCuM / 10 * 30);
    const helperDays      = masonDays;
    const masonCost       = masonDays  * (parseFloat(masonRate?.rate)  || 800);
    const helperCost      = helperDays * (parseFloat(helperRate?.rate) || 500);
    const totalLabourCost = masonCost + helperCost;

    const totalMaterialCost = totalBrickCost + totalCementCost + totalSandCost;
    const totalCost         = totalMaterialCost + totalLabourCost;

    const breakdown = [
      { category: 'Red Bricks',          qty: redBricks,                         unit: 'pieces',   rate: parseFloat(redCostPerUnit.toFixed(2)),   total: parseFloat(redBrickCost.toFixed(2)),    pct: totalCost > 0 ? parseFloat((redBrickCost    / totalCost * 100).toFixed(1)) : 0, color: 'red'    },
      { category: 'White Cement Blocks', qty: whiteBricks,                       unit: 'pieces',   rate: parseFloat(whiteCostPerUnit.toFixed(2)), total: parseFloat(whiteBrickCost.toFixed(2)),  pct: totalCost > 0 ? parseFloat((whiteBrickCost  / totalCost * 100).toFixed(1)) : 0, color: 'blue'   },
      { category: 'Cement',              qty: parseFloat(cementBags.toFixed(2)), unit: 'bags',     rate: parseFloat(cementPerBag.toFixed(2)),     total: parseFloat(totalCementCost.toFixed(2)), pct: totalCost > 0 ? parseFloat((totalCementCost / totalCost * 100).toFixed(1)) : 0, color: 'blue'   },
      { category: 'Sand',                qty: parseFloat(sandTons.toFixed(2)),   unit: 'tons',     rate: parseFloat(sandPerTon.toFixed(2)),       total: parseFloat(totalSandCost.toFixed(2)),   pct: totalCost > 0 ? parseFloat((totalSandCost   / totalCost * 100).toFixed(1)) : 0, color: 'teal'   },
      { category: 'Labour',              qty: masonDays + helperDays,            unit: 'man-days', rate: parseFloat(((masonCost + helperCost) / (masonDays + helperDays || 1)).toFixed(2)), total: parseFloat(totalLabourCost.toFixed(2)), pct: totalCost > 0 ? parseFloat((totalLabourCost / totalCost * 100).toFixed(1)) : 0, color: 'purple' },
    ];

    res.json({
      success: true, project_id, generated_at: new Date().toISOString(),
      quantities: { red_bricks: redBricks, white_bricks: whiteBricks, cement_bags: parseFloat(cementBags.toFixed(2)), sand_tons: parseFloat(sandTons.toFixed(2)), volume_cum: volCuM, mason_days: masonDays, helper_days: helperDays },
      rates_used: { red_brick_per_piece: parseFloat(redCostPerUnit.toFixed(2)), white_brick_per_piece: parseFloat(whiteCostPerUnit.toFixed(2)), cement_per_bag: parseFloat(cementPerBag.toFixed(2)), sand_per_ton: parseFloat(sandPerTon.toFixed(2)), mason_per_day: parseFloat(masonRate?.rate || 800), helper_per_day: parseFloat(helperRate?.rate || 500) },
      cost_summary: { bricks: parseFloat(totalBrickCost.toFixed(2)), cement: parseFloat(totalCementCost.toFixed(2)), sand: parseFloat(totalSandCost.toFixed(2)), labour: parseFloat(totalLabourCost.toFixed(2)), materials: parseFloat(totalMaterialCost.toFixed(2)), total: parseFloat(totalCost.toFixed(2)) },
      breakdown,
      note: "Labour estimated at 1 mason + 1 helper per 10m³ per day × 30 days",
    });
  } catch (err) {
    console.error("Review error:", err);
    res.status(500).json({ error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════
// TAKEOFF (QTO)
// ═══════════════════════════════════════════════════════════

app.get("/projects/:project_id/takeoff", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  const { project_id } = req.params;
  await withCompany(company_id);

  try {
    const { data: plans } = await supabase
      .from("floor_plans").select("id, raw_ocr_data, edited_components, created_at")
      .eq("project_id", project_id).eq("company_id", company_id)
      .eq("ocr_status", "done").order("created_at", { ascending: false }).limit(1);

    if (!plans?.length) {
      return res.status(404).json({ error: "No OCR data found. Please upload a floor plan first." });
    }

    const { data: estimations } = await supabase
      .from("material_estimations").select("*")
      .eq("project_id", project_id).eq("company_id", company_id)
      .order("created_at", { ascending: false }).limit(1);

    const snap    = estimations?.[0]?.formula_snapshot || {};
    const ocr     = applyEdits(plans[0].raw_ocr_data, plans[0].edited_components);
    const summary = ocr.summary || {};
    const { zones, internal, external, doors: ocrDoors, windows: ocrWindows } = normalizeOCR(ocr);

    const totalAreaSqft = summary.total_area_sqft || 0;
    const totalAreaSqM  = parseFloat((totalAreaSqft * 0.0929).toFixed(3));
    const perimeterM    = parseFloat((4 * Math.sqrt(totalAreaSqM)).toFixed(2));

    const thicknessInFeet = (inch) => {
      if (inch === 9) return 0.75;
      if (inch === 6) return 0.50;
      if (inch === 4) return 0.33;
      if (inch === 8) return 0.67;
      return inch / 12;
    };

    const avgExtLenFt = external.length > 0
      ? (perimeterM * 3.281) / external.reduce((s, w) => s + (w.count || 1), 0) : 10;
    const avgIntLenFt = internal.length > 0
      ? (totalAreaSqft / internal.reduce((s, w) => s + (w.count || 1), 0)) / 10 : 8;

    const buildWallRows = (wallList, isExt) =>
      wallList.map(w => {
        const nos     = w.count || 1;
        const L       = isExt ? avgExtLenFt : avgIntLenFt;
        const H       = w.height_ft || 10;
        const B       = thicknessInFeet(w.thickness_inch || 9);
        const volCuFt = parseFloat((L * B * H * nos).toFixed(3));
        const volCuM  = parseFloat((volCuFt * 0.0283168).toFixed(4));
        return { description: `${isExt ? 'Ext' : 'Int'} Wall ${w.thickness_inch || 9}"`, nos, L: parseFloat(L.toFixed(2)), B, H, qty_cuft: volCuFt, qty_cum: volCuM, unit: 'Cu.Ft', type: isExt ? 'external' : 'internal' };
      });

    const allWallRows        = [...buildWallRows(external, true), ...buildWallRows(internal, false)];
    const totalBrickworkCuFt = parseFloat(allWallRows.reduce((s, w) => s + w.qty_cuft, 0).toFixed(3));
    const totalBrickworkCuM  = parseFloat((totalBrickworkCuFt * 0.0283168).toFixed(4));

    const windowRows = ocrWindows.map(w => ({
      description: `Window ${w.size_ft?.width || 0}×${w.size_ft?.height || 0}ft`,
      nos: w.count || 1, width_ft: w.size_ft?.width || 0, height_ft: w.size_ft?.height || 0,
      area_sqft: parseFloat(((w.size_ft?.width || 0) * (w.size_ft?.height || 0) * (w.count || 1)).toFixed(2)),
      unit: 'Sqft', type: 'window',
    }));
    const doorRows = ocrDoors.map(d => ({
      description: `Door ${d.size_ft?.width || 0}×${d.size_ft?.height || 0}ft`,
      nos: d.count || 1, width_ft: d.size_ft?.width || 0, height_ft: d.size_ft?.height || 0,
      area_sqft: parseFloat(((d.size_ft?.width || 0) * (d.size_ft?.height || 0) * (d.count || 1)).toFixed(2)),
      unit: 'Sqft', type: 'door',
    }));

    const totalWindowArea  = windowRows.reduce((s, w) => s + w.area_sqft, 0);
    const totalDoorArea    = doorRows.reduce((s, d)   => s + d.area_sqft, 0);
    const wallSurfaceArea  = parseFloat(allWallRows.reduce((s, w) => s + (w.L * w.H * w.nos), 0).toFixed(2));
    const plasterArea      = parseFloat(Math.max(0, wallSurfaceArea - totalWindowArea - totalDoorArea).toFixed(2));
    const electricalPoints = Math.ceil(totalAreaSqft / 50);
    const plumbingPoints   = Math.ceil(totalAreaSqft / 100);

    res.json({
      success: true, project_id, floor_plan_id: plans[0].id, generated_at: new Date().toISOString(),
      summary: { total_area_sqft: totalAreaSqft, total_area_sqm: totalAreaSqM, perimeter_m: perimeterM, total_walls: allWallRows.length, total_windows: windowRows.length, total_doors: doorRows.length, total_zones: zones.length },
      tabs: {
        brickwork: { label: 'Brickwork', rows: allWallRows, totals: { total_cuft: totalBrickworkCuFt, total_cum: totalBrickworkCuM } },
        sitework:  { label: 'Sitework',  rows: [
          { description: 'Earth Work Excavation',      nos: 1, qty: parseFloat((totalAreaSqM * 0.6).toFixed(3)),         unit: 'Cu.M', notes: 'Estimated at 0.6m depth' },
          { description: 'PCC 1:4:8 Under Foundation', nos: 1, qty: parseFloat((totalAreaSqM * 0.15).toFixed(3)),        unit: 'Cu.M', notes: '150mm thick' },
          { description: 'Backfilling',                nos: 1, qty: parseFloat((totalAreaSqM * 0.2).toFixed(3)),         unit: 'Cu.M', notes: '1/3 of excavation' },
          { description: 'Sand Filling in Plinth',     nos: 1, qty: parseFloat((totalAreaSqM * 0.3).toFixed(3)),         unit: 'Cu.M', notes: '300mm thick bed' },
        ]},
        structure: { label: 'Structure', rows: [
          { description: 'RCC M20 (Columns + Beams)', nos: 1, qty: parseFloat((totalAreaSqM * 0.08).toFixed(3)),         unit: 'Cu.M', notes: 'Estimated 8% of floor area' },
          { description: 'RCC Slab (150mm)',           nos: 1, qty: parseFloat((totalAreaSqM * 0.15).toFixed(3)),         unit: 'Cu.M', notes: '150mm thick' },
          { description: 'Steel Reinforcement',        nos: 1, qty: parseFloat((totalAreaSqM * 0.08 * 120).toFixed(1)), unit: 'Kg',   notes: '120 kg/m³ of RCC' },
          { description: 'Brickwork (Total)',          nos: 1, qty: totalBrickworkCuFt,                                   unit: 'Cu.Ft',notes: 'From OCR floor plan' },
        ]},
        finishing: { label: 'Finishing', rows: [
          { description: 'Wall Plastering (12mm)', nos: 2, qty: parseFloat((plasterArea * 2).toFixed(2)), unit: 'Sqft', notes: 'Both sides of walls' },
          { description: 'Ceiling Plastering',     nos: 1, qty: parseFloat(totalAreaSqft.toFixed(2)),     unit: 'Sqft', notes: 'Total floor area' },
          { description: 'Flooring (Vitrified)',   nos: 1, qty: parseFloat(totalAreaSqft.toFixed(2)),     unit: 'Sqft', notes: 'Total floor area' },
          { description: 'White Wash / Paint',     nos: 2, qty: parseFloat((plasterArea * 2).toFixed(2)), unit: 'Sqft', notes: '2 coats' },
        ]},
        mep: { label: 'MEP', rows: [
          { description: 'Electrical Points', nos: 1, qty: electricalPoints,                unit: 'Points', notes: 'Estimated 1 per 50 sqft' },
          { description: 'Plumbing Points',   nos: 1, qty: plumbingPoints,                  unit: 'Points', notes: 'Estimated 1 per 100 sqft' },
          { description: 'Drainage Points',   nos: 1, qty: Math.ceil(plumbingPoints * 0.8), unit: 'Points', notes: '80% of plumbing points' },
        ]},
        openings: { label: 'Openings', windows: windowRows, doors: doorRows, totals: { window_area_sqft: parseFloat(totalWindowArea.toFixed(2)), door_area_sqft: parseFloat(totalDoorArea.toFixed(2)), total_area_sqft: parseFloat((totalWindowArea + totalDoorArea).toFixed(2)) } },
      },
      zones: zones.map(z => ({ name: z.label || z.name, zone_id: z.id || z.zone_id, area_sqft: z.area_sqft || 0, area_sqm: parseFloat(((z.area_sqft || 0) * 0.0929).toFixed(2)), pct_of_total: totalAreaSqft > 0 ? parseFloat(((z.area_sqft || 0) / totalAreaSqft * 100).toFixed(1)) : 0, size: z.size || { length_ft: z.length_ft, width_ft: z.width_ft } })),
      ocr_summary: summary,
    });
  } catch (err) {
    console.error("Takeoff error:", err);
    res.status(500).json({ error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════
// EXPORT — PDF BOQ
// ═══════════════════════════════════════════════════════════

app.get("/projects/:project_id/export/pdf", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  const { project_id } = req.params;
  await withCompany(company_id);

  try {
    const { data: project }     = await supabase.from("projects").select("name, description").eq("id", project_id).eq("company_id", company_id).single();
    const { data: company }     = await supabase.from("companies").select("name").eq("id", company_id).single();
    const { data: estimations } = await supabase.from("material_estimations").select("*").eq("project_id", project_id).eq("company_id", company_id).order("created_at", { ascending: false }).limit(1);
    if (!estimations?.length) return res.status(404).json({ error: "No estimation found. Run Costing first." });
    const { data: rates } = await supabase.from("master_rates").select("*").eq("company_id", company_id).eq("active", true);

    const snap = estimations[0].formula_snapshot;

    const costAtSite = (r) => {
      if (!r) return 0;
      const base      = parseFloat(r.rate)         || 0;
      const gst       = base * (parseFloat(r.gst_pct) || 0) / 100;
      const loading   = parseFloat(r.loading)      || 0;
      const transport = parseFloat(r.transport_km) || 0;
      const unloading = parseFloat(r.unloading)    || 0;
      return base + gst + loading + transport + unloading;
    };

    const findRate = (category, keyword) =>
      (rates || []).find(r => r.category === category && r.material.toLowerCase().includes(keyword.toLowerCase()));

    const redBricks   = snap?.red_brick?.final_with_10pct    || 0;
    const whiteBricks = snap?.white_cement?.final_with_10pct || 0;
    const cementBags  = snap?.cement?.total_bags             || 0;
    const sandTons    = snap?.sand?.total_tons               || 0;
    const volCuM      = snap?.volume_summary?.net_volume_cum || 0;
    const masonDays   = Math.ceil(volCuM / 10 * 30);

    const redRate    = findRate('Bricks', 'Red Brick');
    const whiteRate  = findRate('Bricks', 'White Cement');
    const cementRate = findRate('Cement', '1:4');
    const sandRate   = findRate('Sand',   'River Sand');
    const masonRate  = findRate('Labour', 'Mason');
    const helperRate = findRate('Labour', 'Helper');

    const redCost    = redBricks   * costAtSite(redRate);
    const whiteCost  = whiteBricks * costAtSite(whiteRate);
    const cementCost = cementBags  * costAtSite(cementRate);
    const sandCost   = sandTons    * costAtSite(sandRate);
    const labourCost = (masonDays * (parseFloat(masonRate?.rate) || 800)) + (masonDays * (parseFloat(helperRate?.rate) || 500));
    const totalCost  = redCost + whiteCost + cementCost + sandCost + labourCost;

    const doc = new PDFDocument({ margin: 50, size: 'A4' });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="BOQ_${project?.name || project_id}_${Date.now()}.pdf"`);
    doc.pipe(res);

    const primaryColor = '#1E6FD9';
    const darkColor    = '#0F172A';
    const grayColor    = '#64748B';
    const lightGray    = '#F1F5F9';

    doc.rect(0, 0, doc.page.width, 80).fill(darkColor);
    doc.fillColor('white').fontSize(20).font('Helvetica-Bold').text('ArchiQuant', 50, 20);
    doc.fillColor('#94A3B8').fontSize(9).font('Helvetica').text('BUILDING CONSTRUCTION SUITE', 50, 44);
    doc.fillColor('white').fontSize(14).font('Helvetica-Bold').text('BILL OF QUANTITIES (BOQ)', 50, 58);

    doc.fillColor(darkColor).fontSize(11).font('Helvetica-Bold').text(company?.name || 'Company', 50, 100);
    doc.fillColor(grayColor).fontSize(10).font('Helvetica').text(`Project: ${project?.name || 'Project'}`, 50, 116);
    doc.text(`Generated: ${new Date().toLocaleDateString('en-IN')}`, 50, 130);
    doc.text(`Report Type: Material Quantity & Cost BOQ`, 50, 144);

    doc.moveTo(50, 165).lineTo(doc.page.width - 50, 165).strokeColor(primaryColor).lineWidth(2).stroke();
    doc.rect(50, 175, doc.page.width - 100, 60).fill(lightGray);
    doc.fillColor(darkColor).fontSize(10).font('Helvetica-Bold').text('PROJECT SUMMARY', 60, 183);

    const summaryItems = [
      ['Floor Area',    `${(snap?.ocr_summary?.total_area_sqft || 0).toFixed(0)} Sqft`],
      ['Red Bricks',    `${Math.ceil(redBricks)} pcs`],
      ['Cement Blocks', `${Math.ceil(whiteBricks)} pcs`],
      ['Cement Bags',   `${parseFloat(cementBags).toFixed(1)} bags`],
      ['Sand',          `${parseFloat(sandTons).toFixed(2)} tons`],
    ];
    let sx = 60;
    summaryItems.forEach(([label, value]) => {
      doc.fillColor(grayColor).fontSize(8).font('Helvetica').text(label, sx, 197);
      doc.fillColor(primaryColor).fontSize(10).font('Helvetica-Bold').text(value, sx, 209);
      sx += 95;
    });

    let y = 255;
    doc.fillColor(darkColor).fontSize(12).font('Helvetica-Bold').text('DETAILED BILL OF QUANTITIES', 50, y);
    y += 20;

    const cols = [30, 200, 60, 80, 80, 80];
    const colX = [50];
    cols.forEach((w, i) => colX.push(colX[i] + w));

    doc.rect(50, y, doc.page.width - 100, 22).fill(darkColor);
    ['Sl.', 'Description', 'Qty', 'Unit', 'Rate (₹)', 'Amount (₹)'].forEach((h, i) => {
      doc.fillColor('white').fontSize(9).font('Helvetica-Bold')
         .text(h, colX[i] + 4, y + 7, { width: cols[i] - 8, align: i > 1 ? 'right' : 'left' });
    });
    y += 22;

    const boqRows = [
      ['01', 'Red Brick (9" Walls)',               Math.ceil(redBricks).toString(),    'Pieces', costAtSite(redRate).toFixed(2),    redCost.toFixed(2)],
      ['02', 'White Cement Block (4"/6")',          Math.ceil(whiteBricks).toString(),  'Pieces', costAtSite(whiteRate).toFixed(2),  whiteCost.toFixed(2)],
      ['03', 'Cement in CM 1:4 (18mm thk)',         parseFloat(cementBags).toFixed(2), 'Bags',   costAtSite(cementRate).toFixed(2), cementCost.toFixed(2)],
      ['04', 'River Sand',                          parseFloat(sandTons).toFixed(3),   'Tons',   costAtSite(sandRate).toFixed(2),   sandCost.toFixed(2)],
      ['05', `Mason (Skilled) — ${masonDays} days`,    masonDays.toString(),            'Days',   (parseFloat(masonRate?.rate) || 800).toFixed(2), (masonDays * (parseFloat(masonRate?.rate) || 800)).toFixed(2)],
      ['06', `Helper (Unskilled) — ${masonDays} days`, masonDays.toString(),            'Days',   (parseFloat(helperRate?.rate) || 500).toFixed(2), (masonDays * (parseFloat(helperRate?.rate) || 500)).toFixed(2)],
    ];

    boqRows.forEach((row, idx) => {
      doc.rect(50, y, doc.page.width - 100, 20).fill(idx % 2 === 0 ? 'white' : '#F8FAFC');
      row.forEach((cell, i) => {
        doc.fillColor(i === 1 ? darkColor : grayColor).fontSize(9).font(i === 1 ? 'Helvetica-Bold' : 'Helvetica')
           .text(cell, colX[i] + 4, y + 6, { width: cols[i] - 8, align: i > 1 ? 'right' : 'left' });
      });
      doc.moveTo(50, y + 20).lineTo(doc.page.width - 50, y + 20).strokeColor('#E2E8F0').lineWidth(0.5).stroke();
      y += 20;
    });

    doc.rect(50, y, doc.page.width - 100, 28).fill(primaryColor);
    doc.fillColor('white').fontSize(11).font('Helvetica-Bold').text('GRAND TOTAL', 54, y + 8);
    doc.fillColor('white').fontSize(12).font('Helvetica-Bold').text(`Rs. ${totalCost.toFixed(2)}`, colX[5] + 4, y + 8, { width: cols[5] - 8, align: 'right' });
    y += 40;

    doc.fillColor(grayColor).fontSize(9).font('Helvetica').text(`Amount in Lakhs: Rs. ${(totalCost / 100000).toFixed(2)} Lakhs`, 50, y);
    y += 30;

    doc.fillColor(darkColor).fontSize(11).font('Helvetica-Bold').text('RATES USED (incl. GST + Loading)', 50, y);
    y += 16;

    [
      ['Red Brick',          `Rs. ${costAtSite(redRate).toFixed(2)}/piece`],
      ['White Cement Block', `Rs. ${costAtSite(whiteRate).toFixed(2)}/piece`],
      ['Cement',             `Rs. ${costAtSite(cementRate).toFixed(2)}/bag`],
      ['Sand',               `Rs. ${costAtSite(sandRate).toFixed(2)}/ton`],
      ['Mason',              `Rs. ${parseFloat(masonRate?.rate || 800).toFixed(2)}/day`],
      ['Helper',             `Rs. ${parseFloat(helperRate?.rate || 500).toFixed(2)}/day`],
    ].forEach(([label, value]) => {
      doc.rect(50, y, doc.page.width - 100, 18).fill(y % 36 === 0 ? lightGray : 'white');
      doc.fillColor(grayColor).fontSize(9).font('Helvetica').text(label, 60, y + 5);
      doc.fillColor(primaryColor).fontSize(9).font('Helvetica-Bold').text(value, 200, y + 5);
      y += 18;
    });

    y += 20;
    doc.moveTo(50, y).lineTo(doc.page.width - 50, y).strokeColor('#E2E8F0').lineWidth(1).stroke();
    y += 10;
    doc.fillColor(grayColor).fontSize(8).font('Helvetica')
       .text('This BOQ is generated by ArchiQuant. Quantities are estimated from OCR floor plan analysis. Actual quantities may vary.', 50, y, { width: doc.page.width - 100, align: 'center' });

    doc.end();
  } catch (err) {
    console.error("PDF export error:", err);
    if (!res.headersSent) res.status(500).json({ error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════
// EXPORT — EXCEL BOQ
// ═══════════════════════════════════════════════════════════

app.get("/projects/:project_id/export/excel", authMiddleware, async (req, res) => {
  const { company_id } = req.user;
  const { project_id } = req.params;
  await withCompany(company_id);

  try {
    const { data: project }     = await supabase.from("projects").select("name").eq("id", project_id).eq("company_id", company_id).single();
    const { data: company }     = await supabase.from("companies").select("name").eq("id", company_id).single();
    const { data: estimations } = await supabase.from("material_estimations").select("*").eq("project_id", project_id).eq("company_id", company_id).order("created_at", { ascending: false }).limit(1);
    if (!estimations?.length) return res.status(404).json({ error: "No estimation found." });
    const { data: rates } = await supabase.from("master_rates").select("*").eq("company_id", company_id).eq("active", true);

    const snap = estimations[0].formula_snapshot;

    const costAtSite = (r) => {
      if (!r) return 0;
      const base      = parseFloat(r.rate)         || 0;
      const gst       = base * (parseFloat(r.gst_pct) || 0) / 100;
      const loading   = parseFloat(r.loading)      || 0;
      const transport = parseFloat(r.transport_km) || 0;
      const unloading = parseFloat(r.unloading)    || 0;
      return base + gst + loading + transport + unloading;
    };

    const findRate = (category, keyword) =>
      (rates || []).find(r => r.category === category && r.material.toLowerCase().includes(keyword.toLowerCase()));

    const redBricks   = snap?.red_brick?.final_with_10pct    || 0;
    const whiteBricks = snap?.white_cement?.final_with_10pct || 0;
    const cementBags  = snap?.cement?.total_bags             || 0;
    const sandTons    = snap?.sand?.total_tons               || 0;
    const volCuM      = snap?.volume_summary?.net_volume_cum || 0;
    const masonDays   = Math.ceil(volCuM / 10 * 30);

    const redRate    = findRate('Bricks', 'Red Brick');
    const whiteRate  = findRate('Bricks', 'White Cement');
    const cementRate = findRate('Cement', '1:4');
    const sandRate   = findRate('Sand',   'River Sand');
    const masonRate  = findRate('Labour', 'Mason');
    const helperRate = findRate('Labour', 'Helper');

    const redCost    = redBricks   * costAtSite(redRate);
    const whiteCost  = whiteBricks * costAtSite(whiteRate);
    const cementCost = cementBags  * costAtSite(cementRate);
    const sandCost   = sandTons    * costAtSite(sandRate);
    const masonCost  = masonDays   * (parseFloat(masonRate?.rate)  || 800);
    const helperCost = masonDays   * (parseFloat(helperRate?.rate) || 500);
    const totalCost  = redCost + whiteCost + cementCost + sandCost + masonCost + helperCost;

    const wb = new ExcelJS.Workbook();
    wb.creator = 'ArchiQuant';
    wb.created = new Date();

    const boqSheet = wb.addWorksheet('BOQ', { pageSetup: { paperSize: 9, orientation: 'portrait' } });
    boqSheet.columns = [
      { key: 'sl', width: 6 }, { key: 'desc', width: 40 }, { key: 'qty', width: 14 },
      { key: 'unit', width: 12 }, { key: 'rate', width: 16 }, { key: 'amount', width: 18 },
    ];

    boqSheet.mergeCells('A1:F1');
    boqSheet.getCell('A1').value = 'ArchiQuant — Bill of Quantities (BOQ)';
    boqSheet.getCell('A1').font  = { bold: true, size: 16, color: { argb: 'FF1E6FD9' } };
    boqSheet.getCell('A1').alignment = { horizontal: 'center' };
    boqSheet.getRow(1).height = 30;

    boqSheet.mergeCells('A2:F2');
    boqSheet.getCell('A2').value = `Company: ${company?.name}  |  Project: ${project?.name}  |  Date: ${new Date().toLocaleDateString('en-IN')}`;
    boqSheet.getCell('A2').font      = { size: 10, color: { argb: 'FF64748B' } };
    boqSheet.getCell('A2').alignment = { horizontal: 'center' };
    boqSheet.getRow(2).height = 20;
    boqSheet.addRow([]);

    const headerRow = boqSheet.addRow(['Sl.No', 'Description', 'Quantity', 'Unit', 'Rate (₹)', 'Amount (₹)']);
    headerRow.height = 22;
    headerRow.eachCell(cell => {
      cell.fill      = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF0F172A' } };
      cell.font      = { bold: true, color: { argb: 'FFFFFFFF' }, size: 10 };
      cell.alignment = { horizontal: 'center', vertical: 'middle' };
      cell.border    = { top: { style: 'thin', color: { argb: 'FF1E6FD9' } }, bottom: { style: 'thin', color: { argb: 'FF1E6FD9' } }, left: { style: 'thin', color: { argb: 'FF1E6FD9' } }, right: { style: 'thin', color: { argb: 'FF1E6FD9' } } };
    });

    [
      ['01', 'Red Brick (9" Walls)',               Math.ceil(redBricks),              'Pieces', costAtSite(redRate).toFixed(2),    redCost.toFixed(2)],
      ['02', 'White Cement Block (4" / 6")',        Math.ceil(whiteBricks),            'Pieces', costAtSite(whiteRate).toFixed(2),  whiteCost.toFixed(2)],
      ['03', 'Cement in CM 1:4 (18mm plaster)',    parseFloat(cementBags).toFixed(2), 'Bags',   costAtSite(cementRate).toFixed(2), cementCost.toFixed(2)],
      ['04', 'River Sand',                          parseFloat(sandTons).toFixed(3),  'Tons',   costAtSite(sandRate).toFixed(2),   sandCost.toFixed(2)],
      ['05', `Mason (Skilled) — ${masonDays} days`,    masonDays, 'Days', (parseFloat(masonRate?.rate)  || 800).toFixed(2), masonCost.toFixed(2)],
      ['06', `Helper (Unskilled) — ${masonDays} days`, masonDays, 'Days', (parseFloat(helperRate?.rate) || 500).toFixed(2), helperCost.toFixed(2)],
    ].forEach((row, idx) => {
      const dataRow = boqSheet.addRow(row);
      dataRow.height = 18;
      const bgColor  = idx % 2 === 0 ? 'FFFFFFFF' : 'FFF8FAFC';
      dataRow.eachCell((cell, colNum) => {
        cell.fill      = { type: 'pattern', pattern: 'solid', fgColor: { argb: bgColor } };
        cell.font      = { size: 10, bold: colNum === 2, color: { argb: colNum === 2 ? 'FF1E293B' : 'FF64748B' } };
        cell.alignment = { horizontal: colNum > 2 ? 'right' : 'left', vertical: 'middle' };
        cell.border    = { bottom: { style: 'thin', color: { argb: 'FFE2E8F0' } } };
      });
    });

    const totalRow = boqSheet.addRow(['', 'GRAND TOTAL', '', '', '', totalCost.toFixed(2)]);
    totalRow.height = 24;
    totalRow.eachCell(cell => {
      cell.fill      = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1E6FD9' } };
      cell.font      = { bold: true, color: { argb: 'FFFFFFFF' }, size: 11 };
      cell.alignment = { horizontal: 'right', vertical: 'middle' };
    });
    boqSheet.getCell(`B${totalRow.number}`).alignment = { horizontal: 'left', vertical: 'middle' };
    boqSheet.addRow([]);
    boqSheet.mergeCells(`A${boqSheet.rowCount}:F${boqSheet.rowCount}`);
    boqSheet.getCell(`A${boqSheet.rowCount}`).value = `Total Amount: Rs. ${(totalCost / 100000).toFixed(2)} Lakhs`;
    boqSheet.getCell(`A${boqSheet.rowCount}`).font  = { italic: true, color: { argb: 'FF64748B' }, size: 9 };

    // ── BRICK WORK CALCULATION sheet — mirrors the client's BOQ Excel layout:
    //    Table 1 = Gross wall volume, Table 2 = Window/Opening deductions,
    //    Table 3 = Door deductions, then Net volume → bricks (×500/m³ + buffer).
    const brickSheet = wb.addWorksheet('Brick Work Calculation');
    brickSheet.columns = [
      { key: 'desc', width: 28 }, { key: 'nos', width: 8 },
      { key: 'L', width: 11 }, { key: 'B', width: 11 }, { key: 'H', width: 11 },
      { key: 'volCuft', width: 15 }, { key: 'volCuM', width: 15 },
    ];
    const FT3_TO_M3 = 0.0283168;
    const bufferPct = snap?.buffer_pct ?? snap?.formulas_used?.buffer_pct ?? 10;

    brickSheet.mergeCells('A1:G1');
    brickSheet.getCell('A1').value = 'BRICK WORK CALCULATION';
    brickSheet.getCell('A1').font  = { bold: true, size: 15, color: { argb: 'FFDC2626' } };
    brickSheet.getCell('A1').alignment = { horizontal: 'center' };
    brickSheet.getRow(1).height = 28;
    brickSheet.addRow([]);

    // Helper: section banner spanning A:G
    const sectionBanner = (title, argb) => {
      const r = brickSheet.addRow([title]);
      brickSheet.mergeCells(`A${r.number}:G${r.number}`);
      r.height = 22;
      r.getCell(1).fill      = { type: 'pattern', pattern: 'solid', fgColor: { argb } };
      r.getCell(1).font      = { bold: true, color: { argb: 'FFFFFFFF' }, size: 11 };
      r.getCell(1).alignment = { horizontal: 'left', vertical: 'middle', indent: 1 };
    };
    // Helper: column header row
    const tableHeader = (cells, argb) => {
      const r = brickSheet.addRow(cells);
      r.height = 18;
      r.eachCell(cell => {
        cell.fill      = { type: 'pattern', pattern: 'solid', fgColor: { argb } };
        cell.font      = { bold: true, color: { argb: 'FFFFFFFF' }, size: 9 };
        cell.alignment = { horizontal: 'center', vertical: 'middle' };
      });
      return r;
    };
    // Helper: data row with zebra + borders
    const dataRow = (cells, idx, tint) => {
      const r = brickSheet.addRow(cells);
      r.height = 16;
      r.eachCell((cell, col) => {
        cell.fill      = { type: 'pattern', pattern: 'solid', fgColor: { argb: idx % 2 === 0 ? 'FFFFFFFF' : tint } };
        cell.font      = { size: 9 };
        cell.alignment = { horizontal: col === 1 ? 'left' : 'center' };
        cell.border    = { bottom: { style: 'thin', color: { argb: 'FFE2E8F0' } } };
      });
      return r;
    };
    // Helper: subtotal row
    const subtotalRow = (label, cuft, argb) => {
      const r = brickSheet.addRow([label, '', '', '', '', (cuft || 0).toFixed(3), ((cuft || 0) * FT3_TO_M3).toFixed(4)]);
      r.height = 18;
      r.eachCell(cell => {
        cell.fill      = { type: 'pattern', pattern: 'solid', fgColor: { argb } };
        cell.font      = { bold: true, color: { argb: 'FFFFFFFF' }, size: 9 };
        cell.alignment = { horizontal: 'center' };
      });
      r.getCell(1).alignment = { horizontal: 'left', indent: 1 };
      return r;
    };

    // ── TABLE 1 — GROSS WALL VOLUME ──────────────────────────────
    sectionBanner('TABLE 1 — GROSS WALL VOLUME', 'FF0F172A');
    tableHeader(['Description', 'Nos', 'L (ft)', 'B (ft)', 'H (ft)', 'Vol (Cu.Ft)', 'Vol (m³)'], 'FF334155');
    const walls = snap?.wall_breakdown || [];
    walls.forEach((w, idx) => {
      const volCuft = w.wall_volume_cuft ?? ((w.L || 0) * (w.thickness_ft || 0) * (w.H || 0) * (w.nos || 1));
      dataRow([
        w.description || '', w.nos || 1,
        (w.L || 0).toFixed(2), (w.thickness_ft || 0).toFixed(3), (w.H || 0).toFixed(2),
        volCuft.toFixed(3), (w.wall_volume_cum ?? volCuft * FT3_TO_M3).toFixed(4),
      ], idx, 'FFF8FAFC');
    });
    const grossCuft = snap?.volume_summary?.gross_volume_cuft || 0;
    subtotalRow('GROSS TOTAL', grossCuft, 'FF0F172A');
    brickSheet.addRow([]);

    // ── TABLE 2 — DEDUCTIONS: WINDOWS / OPENINGS ─────────────────
    sectionBanner('TABLE 2 — DEDUCTIONS (Windows / Vents / Openings)', 'FFB45309');
    tableHeader(['Opening (L×H, thk)', 'Nos', 'Face (Sq.Ft)', '', '', 'Vol (Cu.Ft)', 'Vol (m³)'], 'FFD97706');
    const winItems = snap?.deductions?.windows?.items || [];
    winItems.forEach((o, idx) => {
      dataRow([
        o.description || '', o.nos || 1, (o.face_sqft || 0).toFixed(2), '', '',
        (o.volume_cuft || 0).toFixed(3), ((o.volume_cuft || 0) * FT3_TO_M3).toFixed(4),
      ], idx, 'FFFFFBEB');
    });
    const winCuft = snap?.deductions?.windows?.volume_cuft || 0;
    subtotalRow('WINDOW / OPENING DEDUCTION', winCuft, 'FFB45309');
    brickSheet.addRow([]);

    // ── TABLE 3 — DEDUCTIONS: DOORS ──────────────────────────────
    sectionBanner('TABLE 3 — DEDUCTIONS (Doors)', 'FF7C2D12');
    tableHeader(['Door (L×H, thk)', 'Nos', 'Face (Sq.Ft)', '', '', 'Vol (Cu.Ft)', 'Vol (m³)'], 'FF9A3412');
    const doorItems = snap?.deductions?.doors?.items || [];
    doorItems.forEach((o, idx) => {
      dataRow([
        o.description || '', o.nos || 1, (o.face_sqft || 0).toFixed(2), '', '',
        (o.volume_cuft || 0).toFixed(3), ((o.volume_cuft || 0) * FT3_TO_M3).toFixed(4),
      ], idx, 'FFFEF2F2');
    });
    const doorCuft = snap?.deductions?.doors?.volume_cuft || 0;
    subtotalRow('DOOR DEDUCTION', doorCuft, 'FF7C2D12');
    brickSheet.addRow([]);

    // ── NET VOLUME + BRICK COUNT ─────────────────────────────────
    const netCuft = snap?.volume_summary?.net_volume_cuft ?? Math.max(0, grossCuft - winCuft - doorCuft);
    const netCuM  = snap?.volume_summary?.net_volume_cum  ?? parseFloat((netCuft * FT3_TO_M3).toFixed(4));
    subtotalRow(`NET VOLUME  =  Gross − Windows − Doors`, netCuft, 'FF065F46');

    const eqRow = brickSheet.addRow([`Bricks = ${netCuM.toFixed(4)} m³ × 500 + ${bufferPct}% wastage`, '', '', '', '', '', snap?.grand_total?.final_bricks || 0]);
    eqRow.height = 20;
    eqRow.eachCell(cell => {
      cell.fill      = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFDC2626' } };
      cell.font      = { bold: true, color: { argb: 'FFFFFFFF' }, size: 10 };
      cell.alignment = { horizontal: 'center', vertical: 'middle' };
    });
    brickSheet.mergeCells(`A${eqRow.number}:F${eqRow.number}`);
    eqRow.getCell(1).alignment = { horizontal: 'left', vertical: 'middle', indent: 1 };

    // Red vs White split
    brickSheet.addRow([]);
    const splitHdr = tableHeader(['Brick Type', 'Gross', 'Deducted', 'Net', `+${bufferPct}% Final`, '', ''], 'FFDC2626');
    [
      ['Red Brick (9")', snap?.red_brick?.gross_bricks, snap?.red_brick?.deducted, snap?.red_brick?.net_bricks, snap?.red_brick?.final_with_10pct],
      ['White Cement Block (4"/6")', snap?.white_cement?.gross_bricks, snap?.white_cement?.deducted, snap?.white_cement?.net_bricks, snap?.white_cement?.final_with_10pct],
    ].forEach((r, idx) => dataRow([r[0], r[1] || 0, r[2] || 0, r[3] || 0, r[4] || 0, '', ''], idx, 'FFFFF5F5'));

    const csSheet = wb.addWorksheet('Cement & Sand');
    csSheet.columns = [
      { key: 'mix', width: 12 }, { key: 'bags12', width: 18 }, { key: 'bags18', width: 18 },
      { key: 'sandCuM', width: 16 }, { key: 'sandTon', width: 16 },
    ];
    csSheet.mergeCells('A1:E1');
    csSheet.getCell('A1').value = 'Cement & Sand Quantities (Based on Client Master Data)';
    csSheet.getCell('A1').font  = { bold: true, size: 14, color: { argb: 'FF1E6FD9' } };
    csSheet.getCell('A1').alignment = { horizontal: 'center' };
    csSheet.getRow(1).height = 28;
    csSheet.addRow([]);
    csSheet.mergeCells('A3:E3');
    csSheet.getCell('A3').value = `Net Brickwork Volume: ${(snap?.volume_summary?.net_volume_cum || 0).toFixed(4)} m³`;
    csSheet.getCell('A3').font  = { italic: true, color: { argb: 'FF64748B' } };
    csSheet.addRow([]);

    const csHeader = csSheet.addRow(['Mix', 'Cement (12mm) bags', 'Cement (18mm) bags', 'Sand (m³)', 'Sand (Tons)']);
    csHeader.height = 20;
    csHeader.eachCell(cell => {
      cell.fill      = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1E6FD9' } };
      cell.font      = { bold: true, color: { argb: 'FFFFFFFF' }, size: 10 };
      cell.alignment = { horizontal: 'center', vertical: 'middle' };
    });

    const allMixes = snap?.cement?.all_mixes || {};
    ['1:3', '1:4', '1:5', '1:6'].forEach((mix, idx) => {
      const m   = allMixes[mix] || {};
      const row = csSheet.addRow([`CM ${mix}`, m.cement_bags_12mm || 0, m.cement_bags_18mm || 0, m.sand_cum || 0, m.sand_tons || 0]);
      row.height = 18;
      row.eachCell(cell => {
        cell.fill      = { type: 'pattern', pattern: 'solid', fgColor: { argb: mix === '1:4' ? 'FFEFF6FF' : (idx % 2 === 0 ? 'FFFFFFFF' : 'FFF8FAFC') } };
        cell.font      = { size: 10, bold: mix === '1:4', color: { argb: mix === '1:4' ? 'FF1E6FD9' : 'FF475569' } };
        cell.alignment = { horizontal: 'center' };
        cell.border    = { bottom: { style: 'thin', color: { argb: 'FFE2E8F0' } } };
      });
    });

    const ratesSheet = wb.addWorksheet('Master Rates');
    ratesSheet.columns = [
      { key: 'material', width: 30 }, { key: 'category', width: 14 }, { key: 'rate', width: 12 },
      { key: 'unit', width: 10 }, { key: 'gst', width: 10 }, { key: 'loading', width: 12 },
      { key: 'transport', width: 16 }, { key: 'distance', width: 14 }, { key: 'unloading', width: 12 }, { key: 'total', width: 16 },
    ];
    ratesSheet.mergeCells('A1:J1');
    ratesSheet.getCell('A1').value = 'Master Rate List';
    ratesSheet.getCell('A1').font  = { bold: true, size: 14, color: { argb: 'FF7C3AED' } };
    ratesSheet.getCell('A1').alignment = { horizontal: 'center' };
    ratesSheet.getRow(1).height = 28;
    ratesSheet.addRow([]);

    const ratesHeader = ratesSheet.addRow(['Material', 'Category', 'Rate', 'Unit', 'GST%', 'Loading', 'Transport/km', 'Distance km', 'Unloading', 'Total at Site']);
    ratesHeader.height = 20;
    ratesHeader.eachCell(cell => {
      cell.fill      = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF7C3AED' } };
      cell.font      = { bold: true, color: { argb: 'FFFFFFFF' }, size: 10 };
      cell.alignment = { horizontal: 'center', vertical: 'middle' };
    });

    (rates || []).forEach((r, idx) => {
      const row = ratesSheet.addRow([r.material || '', r.category || '', r.rate || 0, r.unit || '', r.gst_pct || 0, r.loading || 0, r.transport_km || 0, r.distance_km || 0, r.unloading || 0, costAtSite(r).toFixed(2)]);
      row.height = 16;
      row.eachCell(cell => {
        cell.fill      = { type: 'pattern', pattern: 'solid', fgColor: { argb: idx % 2 === 0 ? 'FFFFFFFF' : 'FFF5F3FF' } };
        cell.font      = { size: 9 };
        cell.alignment = { horizontal: 'center' };
        cell.border    = { bottom: { style: 'thin', color: { argb: 'FFE2E8F0' } } };
      });
      ratesSheet.getCell(`A${row.number}`).alignment = { horizontal: 'left' };
    });

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="BOQ_${project?.name || project_id}_${Date.now()}.xlsx"`);
    await wb.xlsx.write(res);
    res.end();

  } catch (err) {
    console.error("Excel export error:", err);
    if (!res.headersSent) res.status(500).json({ error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════
// START SERVER
// ═══════════════════════════════════════════════════════════

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));