import cv2
import easyocr
import re
import json
import numpy as np
import math
import sys
from pdf2image import convert_from_path

MIN_CONF = 0.30
reader = easyocr.Reader(['en'], gpu=False)
input_path = sys.argv[1]

# ─── LOAD ───────────────────────────────────────────────────
if input_path.lower().endswith(".pdf"):
    pages = convert_from_path(input_path, dpi=500)
else:
    pages = [cv2.imread(input_path)]

elements = []

def preprocess(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    gray = cv2.bilateralFilter(gray, 9, 75, 75)
    _, th = cv2.threshold(gray, 150, 255, cv2.THRESH_BINARY)
    return th

for page in pages:
    image = cv2.cvtColor(np.array(page), cv2.COLOR_RGB2BGR)
    processed = preprocess(image)
    for (bbox, text, prob) in reader.readtext(processed):
        if prob < MIN_CONF:
            continue
        x = int(sum(p[0] for p in bbox) / 4)
        y = int(sum(p[1] for p in bbox) / 4)
        elements.append({"text": text.upper(), "x": x, "y": y})

# ─── CLEAN ──────────────────────────────────────────────────
def clean(t):
    t = t.upper().replace("-", "=").replace("_", "")
    t = t.replace("H-", "H=").replace("T-", "T=")
    t = t.replace("D-", "D=").replace("W-", "W=")
    t = t.replace("X", "x")
    return t.strip()

for e in elements:
    e["text"] = clean(e["text"])

# ─── HELPERS ────────────────────────────────────────────────
def dist(a, b):
    return math.hypot(a["x"] - b["x"], a["y"] - b["y"])

def is_dup(x, y, positions, th=25):
    return any(abs(x - px) < th and abs(y - py) < th for px, py in positions)

def parse_fi(text):
    text = text.replace(" ", "")
    fm = re.search(r"(\d+)'", text)
    if not fm:
        return None
    feet = int(fm.group(1))
    im = re.search(r"'(\d+)", text)
    fr = re.search(r"(\d+)/(\d+)", text)
    inches = int(im.group(1)) if im else 0
    frac = int(fr.group(1)) / int(fr.group(2)) if fr else 0
    if inches > 12:
        inches = int(str(inches)[0])
    return math.ceil(feet + (inches + frac) / 12)

def parse_size(base):
    # feet'inches" x feet'inches"
    best, best_d = None, 999999
    for e in elements:
        d = dist(base, e)
        if d < 700:
            m = re.search(r"(\d+'\d+(?:\s*\d+/\d+)?\"?)\s*[xX]\s*(\d+'\d+(?:\s*\d+/\d+)?\"?)", e["text"])
            if m:
                w, l = parse_fi(m.group(1)), parse_fi(m.group(2))
                if w and l and 5 <= w <= 50 and 5 <= l <= 50 and d < best_d:
                    best, best_d = (w, l), d
    if best:
        w, l = best
        if w > l: w, l = l, w
        return {"length_ft": l, "width_ft": w}

    # NxM integer — handles "10 x 10", "10' x 10'", "10'x10'" (feet, no inches)
    # Pick the NEAREST size label to the zone centre (not the largest). A room's
    # own size is printed inside it, so it's closest; this stops a small room
    # from inheriting a neighbouring larger room's dimensions.
    best, best_d = None, 700
    for e in elements:
        d = dist(base, e)
        if d < best_d and "D=" not in e["text"] and "W=" not in e["text"]:
            m = re.search(r"(\d{1,2})\s*['’ʼ]?\s*[xX]\s*(\d{1,2})", e["text"])
            if m:
                w, l = int(m.group(1)), int(m.group(2))
                if 5 <= w <= 40 and 5 <= l <= 40:
                    best, best_d = (w, l), d
    if best:
        w, l = best
        if w > l: w, l = l, w
        return {"length_ft": l, "width_ft": w}

    # fallback nearest two numbers
    cands = sorted(
        [(int(n), dist(base, e))
         for e in elements if dist(base, e) < 400
         for n in re.findall(r"\d{1,2}", e["text"]) if 5 <= int(n) <= 40],
        key=lambda x: x[1]
    )[:2]
    if len(cands) >= 2:
        vals = sorted(c[0] for c in cands)
        return {"length_ft": vals[1], "width_ft": vals[0]}
    return None

# Allow ZONE1 / ZONE 1 / ZONE-1 (cleaned to ZONE=1) / ZONE_1 between word and number
ZONE_PAT = r"ZONE[\s=\-]*\d+[A-Z]?"
SIZE_PAT  = r"\d+'\d+\"?x\d+'\d+\"?"
DIRS = {"NORTH", "SOUTH", "EAST", "WEST"}
IGNORE = {"ZONE", "T=", "H=", "D=", "W="}

def nearest_label(base):
    best, best_d = None, 999999
    for e in elements:
        txt = e["text"]
        if any(i in txt for i in IGNORE): continue
        if txt in DIRS: continue
        if re.match(SIZE_PAT, txt): continue
        if re.match(ZONE_PAT, txt): continue
        d = dist(base, e)
        if d < best_d:
            best, best_d = txt, d
    return best

def wall_props(base, max_d=450):
    # Find the NEAREST T= and H= label to this wall (more robust than
    # first-within-200px). Nearest-match keeps each wall pinned to its own
    # T/H even when other walls are within range.
    best_t, bt_d = None, max_d
    best_h, bh_d = None, max_d
    for e in elements:
        d = dist(base, e)
        if d >= max_d:
            continue
        mt = re.search(r"T=?\s*(\d{1,2})", e["text"])
        if mt and d < bt_d:
            best_t, bt_d = int(mt.group(1)), d
        mh = re.search(r"H=?\s*(\d{1,2})", e["text"])
        if mh and d < bh_d:
            best_h, bh_d = int(mh.group(1)), d
    return best_t, best_h

# ─── WALLS WITH IDs ─────────────────────────────────────────
walls = []
iw_n = ew_n = 0
visited = []

for e in elements:
    txt = e["text"].replace("1W", "IW").replace("lW", "IW")
    if any(dist(e, v) < 120 for v in visited):
        continue
    if "IW" in txt:
        t, h = wall_props(e)
        # Use the detected T/H if valid, else fall back to standard defaults
        # so a labelled wall is never dropped just because its T=/H= text was
        # missed or out of range (internal walls default 4" thick, 10 ft high).
        t = t if (t and 3 <= t <= 12) else 4
        h = h if (h and 6 <= h <= 12) else 10
        iw_n += 1
        walls.append({"id": f"iw{iw_n}", "type": "internal",
                       "x": e["x"], "y": e["y"], "thickness_in": t, "height_ft": h})
        visited.append(e)
    elif "EW" in txt:
        t, h = wall_props(e)
        # external walls default 9" thick, 10 ft high
        t = t if (t and 6 <= t <= 15) else 9
        h = h if (h and 8 <= h <= 15) else 10
        ew_n += 1
        walls.append({"id": f"ew{ew_n}", "type": "external",
                       "x": e["x"], "y": e["y"], "thickness_in": t, "height_ft": h})
        visited.append(e)

def nearest_wall(elem, max_d=1500):
    best_id, best_d = None, max_d
    for w in walls:
        d = math.hypot(elem["x"] - w["x"], elem["y"] - w["y"])
        if d < best_d:
            best_id, best_d = w["id"], d
    # Fallback: if nothing within max_d, snap to the absolute nearest wall
    # so on_wall is never null (as long as any wall was detected).
    if best_id is None and walls:
        best_id = min(
            walls,
            key=lambda w: math.hypot(elem["x"] - w["x"], elem["y"] - w["y"]),
        )["id"]
    return best_id

def walls_near(elem, max_d=2500):
    iw = [w["id"] for w in walls if w["type"] == "internal"
          and math.hypot(elem["x"] - w["x"], elem["y"] - w["y"]) < max_d]
    ew = [w["id"] for w in walls if w["type"] == "external"
          and math.hypot(elem["x"] - w["x"], elem["y"] - w["y"]) < max_d]
    return iw, ew

# ─── DOORS WITH IDs ─────────────────────────────────────────
# Handles "D=3x7", "D=4X4", "D=4'x7'"  (optional apostrophe, height 4–8 ft)
doors_dict = {}
door_elems = {}
door_pos = []
door_n = 0

for e in elements:
    m = re.search(r"D=?\s*(\d{1,2})['’]?\s*[xX]\s*(\d{1,2})", e["text"])
    if m:
        w, h = int(m.group(1)), int(m.group(2))
        if 2 <= w <= 6 and 4 <= h <= 8 and not is_dup(e["x"], e["y"], door_pos):
            door_n += 1
            did = f"d{door_n}"
            doors_dict[did] = {"id": did, "on_wall": nearest_wall(e), "width_ft": w, "height_ft": h}
            door_elems[did] = e
            door_pos.append((e["x"], e["y"]))

# ─── WINDOWS WITH IDs ───────────────────────────────────────
# Supports TWO label conventions:
#   A) "W=4x4"               (inline,   complex plan)
#   B) "W1 4'X5'"            (tag+size combined in one label)
#   C) "W1" + "4'X5'"        (tag and size are separate labels)
windows_dict = {}
window_elems = {}
win_pos = []
win_n = 0

def add_window(e, w, h):
    global win_n
    if 2 <= w <= 8 and 2 <= h <= 8 and not is_dup(e["x"], e["y"], win_pos):
        win_n += 1
        wid = f"w{win_n}"
        windows_dict[wid] = {"id": wid, "on_wall": nearest_wall(e),
                              "width_ft": w, "height_ft": h}
        window_elems[wid] = e
        win_pos.append((e["x"], e["y"]))
        return True
    return False

# Pass 1 — inline (A) "W=4x4"  or (B) "W1 4'X5'"
for e in elements:
    txt = e["text"]
    m = re.search(r"W=\s*(\d{1,2})\s*[xX]\s*(\d{1,2})", txt)          # A
    if not m:
        m = re.search(r"W\d+\s+(\d{1,2})['’]?\s*[xX]\s*(\d{1,2})", txt)  # B
    if m:
        add_window(e, int(m.group(1)), int(m.group(2)))

# Pass 2 — detached (C): a "W#" tag with the nearest apostrophe-size label.
# Guards so a ZONE size (e.g. BATH "6'X8'") is NOT mistaken for a window:
#   • size must be within 220px of the W# tag (a window size sits right by it)
#   • size must be CLOSER to the W# tag than to any zone label
zone_pts = [(e["x"], e["y"]) for e in elements if re.match(ZONE_PAT, e["text"])]
w_tags = [e for e in elements if re.fullmatch(r"W\s*\d+", e["text"].strip())]
for tag in w_tags:
    if is_dup(tag["x"], tag["y"], win_pos):
        continue
    best, bd = None, 220
    for e in elements:
        sm = re.fullmatch(r"(\d{1,2})['’]\s*[xX]\s*(\d{1,2})['’]?", e["text"].strip())
        if not sm:
            continue
        sw, sh = int(sm.group(1)), int(sm.group(2))
        d = dist(tag, e)
        if d >= bd or not (2 <= sw <= 8 and 2 <= sh <= 8):
            continue
        if is_dup(e["x"], e["y"], win_pos):
            continue
        # reject if this size sits nearer a zone label than this window tag
        nearest_zone = min((math.hypot(e["x"] - zx, e["y"] - zy)
                            for zx, zy in zone_pts), default=10**9)
        if nearest_zone < d:
            continue
        best, bd = (e, sw, sh), d
    if best:
        add_window(best[0], best[1], best[2])

# ─── ZONES AS DICT ──────────────────────────────────────────
zone_elems = {}
for e in elements:
    if re.match(ZONE_PAT, e["text"]):
        # Normalise "ZONE 1" / "ZONE-1" / "ZONE=1" → "ZONE1"
        zid = re.sub(r"[\s=\-_]", "", e["text"])
        zone_elems[zid] = e

zones_dict = {}
for zid, ze in zone_elems.items():
    size = parse_size(ze)
    area = round(size["length_ft"] * size["width_ft"], 2) if size else None
    label = nearest_label(ze) or "UNKNOWN"
    iw_near, ew_near = walls_near(ze)

    zones_dict[zid] = {
        "id": zid,
        "label": label,
        "width_ft": size["width_ft"] if size else None,
        "length_ft": size["length_ft"] if size else None,
        "area_sqft": area,
        "doors": [],    # filled below via wall connectivity
        "windows": [],  # filled below via wall connectivity
        "connected_internal_walls": iw_near,
        "connected_external_walls": ew_near,
        "total_walls_connected": len(iw_near) + len(ew_near),
    }

# ── Assign doors/windows to zones via wall connectivity ──────
# A door/window belongs to a zone if it sits on one of that zone's walls.
# This is far more reliable than raw proximity from zone-center text.
for zid, zone in zones_dict.items():
    zone_walls = set(zone["connected_internal_walls"] + zone["connected_external_walls"])

    for did, d in doors_dict.items():
        if d["on_wall"] in zone_walls and did not in zone["doors"]:
            zone["doors"].append(did)

    for wid, wi in windows_dict.items():
        if wi["on_wall"] in zone_walls and wid not in zone["windows"]:
            zone["windows"].append(wid)

    # Fallback: proximity from zone center (catches openings whose on_wall is null)
    ze = zone_elems[zid]
    for did, de in door_elems.items():
        if did not in zone["doors"]:
            if math.hypot(ze["x"] - de["x"], ze["y"] - de["y"]) < 1500:
                zone["doors"].append(did)
    for wid, we in window_elems.items():
        if wid not in zone["windows"]:
            if math.hypot(ze["x"] - we["x"], ze["y"] - we["y"]) < 1500:
                zone["windows"].append(wid)

# ─── WALL OUTPUT DICTS ──────────────────────────────────────
def near_wall_ids(wdata, wtype, max_d=2000):
    return [w["id"] for w in walls
            if w["type"] == wtype and w["id"] != wdata["id"]
            and math.hypot(wdata["x"] - w["x"], wdata["y"] - w["y"]) < max_d]

# ── Building bounds (from all wall positions) ───────────────
if walls:
    _xs = [w["x"] for w in walls]
    _ys = [w["y"] for w in walls]
    BX_MIN, BX_MAX = min(_xs), max(_xs)
    BY_MIN, BY_MAX = min(_ys), max(_ys)
    BX_MID = (BX_MIN + BX_MAX) / 2
    BY_MID = (BY_MIN + BY_MAX) / 2
else:
    BX_MIN = BX_MAX = BY_MIN = BY_MAX = BX_MID = BY_MID = 0

# ── Derive compass position from wall location ──────────────
# Image coords: y grows DOWNWARD, x grows RIGHTWARD.
#   low y  → top    → NORTH      high y → bottom → SOUTH
#   low x  → left   → WEST       high x → right  → EAST
# External walls get an edge label; internal walls that sit near the
# centre are "middle", otherwise they take the nearest edge direction.
def derive_position(w):
    span_x = max(BX_MAX - BX_MIN, 1)
    span_y = max(BY_MAX - BY_MIN, 1)
    # normalised 0..1 within building
    nx = (w["x"] - BX_MIN) / span_x
    ny = (w["y"] - BY_MIN) / span_y

    # distance to each edge (0 = on that edge)
    edges = {
        "north": ny,            # near top
        "south": 1 - ny,        # near bottom
        "west":  nx,            # near left
        "east":  1 - nx,        # near right
    }
    nearest = min(edges, key=edges.get)

    if w["type"] == "external":
        return nearest
    # internal: if it's roughly central, call it "middle"
    if 0.30 <= nx <= 0.70 and 0.30 <= ny <= 0.70:
        return "middle"
    return nearest

# ── Derive wall length from the floor plan ──────────────────
# EasyOCR reads text, not lines — but zone dimensions ARE read from the
# plan. A wall bounds a zone, so its length = that zone's edge dimension.
# We pick the nearest zone, then use the wall's position relative to the
# zone centre to decide orientation:
#   wall offset more in X  → vertical wall   → length = zone length_ft
#   wall offset more in Y  → horizontal wall → length = zone width_ft
def derive_wall_length(w):
    best_zid, best_d = None, 10**18
    for zid, ze in zone_elems.items():
        zone = zones_dict.get(zid)
        if not zone or not zone.get("width_ft") or not zone.get("length_ft"):
            continue
        d = math.hypot(w["x"] - ze["x"], w["y"] - ze["y"])
        if d < best_d:
            best_zid, best_d = zid, d
    if best_zid is None:
        return None
    zone = zones_dict[best_zid]
    ze   = zone_elems[best_zid]
    dx = abs(w["x"] - ze["x"])
    dy = abs(w["y"] - ze["y"])
    # vertical wall (on a left/right edge) spans the room's length;
    # horizontal wall (on a top/bottom edge) spans the room's width.
    return zone["length_ft"] if dx >= dy else zone["width_ft"]

internal_walls = {}
external_walls = {}

for w in walls:
    w_doors = [did for did, d in doors_dict.items() if d["on_wall"] == w["id"]]
    w_wins  = [wid for wid, wi in windows_dict.items() if wi["on_wall"] == w["id"]]
    entry = {
        "id": w["id"],
        "position": derive_position(w),
        "height_ft": w["height_ft"],
        "length_ft": derive_wall_length(w),
        "thickness_in": w["thickness_in"],
        "connected": {"doors": w_doors, "windows": w_wins},
    }
    if w["type"] == "internal":
        entry["connects_external"] = near_wall_ids(w, "external")
        internal_walls[w["id"]] = entry
    else:
        entry["connected"]["internal_walls"] = near_wall_ids(w, "internal")
        external_walls[w["id"]] = entry

# ─── OUTPUT ─────────────────────────────────────────────────
total_area = round(sum((z["area_sqft"] or 0) for z in zones_dict.values()), 2)

print(json.dumps({
    "zones": zones_dict,
    "doors": doors_dict,
    "windows": windows_dict,
    "internal_walls": internal_walls,
    "external_walls": external_walls,
    "summary": {
        "total_zones": len(zones_dict),
        "total_doors": len(doors_dict),
        "total_windows": len(windows_dict),
        "total_area_sqft": total_area,
        "total_internal_walls": len(internal_walls),
        "total_external_walls": len(external_walls),
        "detection_strategy": "text_labels",
    },
}, indent=4))
