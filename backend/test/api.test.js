const request = require("supertest");

// ── Mock Supabase: a chainable proxy whose terminal calls resolve to {data:null}.
// This is enough to exercise auth, validation, ownership-gating, 404 and error
// paths deterministically without a real database.
jest.mock("../config/supabase", () => {
  const result = { data: null, error: null };
  const chain = new Proxy({}, {
    get(_t, prop) {
      if (prop === "single" || prop === "maybeSingle") return () => Promise.resolve(result);
      if (prop === "then") return (res, rej) => Promise.resolve(result).then(res, rej);
      return () => chain;
    },
  });
  return { from: () => chain, rpc: () => Promise.resolve(result) };
});
// Avoid loading the real OCR sidecar machinery.
jest.mock("../services/easyocrService", () => ({ runOCR: jest.fn() }));

const { app, signAccessToken, signRefreshToken } = require("../server");

const access  = signAccessToken({ id: "u1", role: "admin" }, { id: "c1", plan: "starter" });
const refresh = signRefreshToken({ id: "u1" }, { id: "c1" });

describe("health & 404", () => {
  test("GET /health → 200 ok", async () => {
    const r = await request(app).get("/health");
    expect(r.status).toBe(200);
    expect(r.body.status).toBe("ok");
  });
  test("unknown route → 404 JSON", async () => {
    const r = await request(app).get("/does-not-exist");
    expect(r.status).toBe(404);
    expect(r.body.error).toBe("Not found");
  });
  test("GET /ready → 200 when DB reachable", async () => {
    const r = await request(app).get("/ready");
    expect(r.status).toBe(200);
    expect(r.body.status).toBe("ready");
  });
  test("every response carries an X-Request-Id header", async () => {
    const r = await request(app).get("/health");
    expect(r.headers["x-request-id"]).toBeDefined();
  });
});

describe("pagination", () => {
  test("GET /projects accepts limit/offset without error", async () => {
    const r = await request(app)
      .get("/projects?limit=10&offset=0")
      .set("Authorization", `Bearer ${access}`);
    expect(r.status).toBe(200);
  });
});

describe("authentication", () => {
  test("no token → 401", async () => {
    const r = await request(app).get("/projects");
    expect(r.status).toBe(401);
  });
  test("garbage token → 401", async () => {
    const r = await request(app).get("/projects").set("Authorization", "Bearer nonsense");
    expect(r.status).toBe(401);
  });
  test("refresh token rejected as access token → 401", async () => {
    const r = await request(app).get("/projects").set("Authorization", `Bearer ${refresh}`);
    expect(r.status).toBe(401);
  });
  test("valid access token passes the auth gate", async () => {
    const r = await request(app).get("/projects").set("Authorization", `Bearer ${access}`);
    expect(r.status).toBe(200);
  });
});

describe("multi-tenant write gating", () => {
  test("estimation on a non-owned project → 404 (ownership check)", async () => {
    const r = await request(app)
      .post("/projects/some-foreign-id/estimations")
      .set("Authorization", `Bearer ${access}`)
      .send({ total_cost: 100, company_id: "victim-tenant" });
    expect(r.status).toBe(404);
  });
});

describe("auth input validation", () => {
  test("register with invalid email → 400", async () => {
    const r = await request(app).post("/auth/register")
      .send({ company_name: "X", company_slug: "xyz", email: "not-an-email", password: "password1" });
    expect(r.status).toBe(400);
  });
  test("register with weak password → 400", async () => {
    const r = await request(app).post("/auth/register")
      .send({ company_name: "X", company_slug: "xyz", email: "a@b.com", password: "123" });
    expect(r.status).toBe(400);
  });
  test("login missing fields → 400", async () => {
    const r = await request(app).post("/auth/login").send({ email: "a@b.com" });
    expect(r.status).toBe(400);
  });
  test("refresh without token → 400", async () => {
    const r = await request(app).post("/auth/refresh").send({});
    expect(r.status).toBe(400);
  });
});
