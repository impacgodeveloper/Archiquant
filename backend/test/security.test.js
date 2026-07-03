const { safeArith, sanitizeBody } = require("../utils/security");

describe("safeArith (RCE guard)", () => {
  test("evaluates plain arithmetic", () => {
    expect(safeArith("0.75 * 0.25", 0)).toBeCloseTo(0.1875);
    expect(safeArith("(1 + 2) * 3", 0)).toBe(9);
  });
  test("rejects code injection → fallback", () => {
    expect(safeArith("require('child_process')", 9)).toBe(9);
    expect(safeArith("process.exit(1)", 7)).toBe(7);
    expect(safeArith("globalThis.foo", 1)).toBe(1);
    expect(safeArith("(()=>1)()", 3)).toBe(3);
  });
  test("handles empty / non-string / NaN", () => {
    expect(safeArith("", 5)).toBe(5);
    expect(safeArith(null, 5)).toBe(5);
    expect(safeArith(undefined, 5)).toBe(5);
    expect(safeArith("1/0", 4)).toBe(4); // Infinity → fallback
  });
});

describe("sanitizeBody (mass-assignment guard)", () => {
  test("strips company_id / id / timestamps, keeps the rest", () => {
    const out = sanitizeBody({
      company_id: "another-tenant", id: "x", created_at: "t", updated_at: "t",
      name: "Red Brick", rate: 8.2,
    });
    expect(out).toEqual({ name: "Red Brick", rate: 8.2 });
  });
  test("returns {} for non-objects", () => {
    expect(sanitizeBody(null)).toEqual({});
    expect(sanitizeBody("str")).toEqual({});
    expect(sanitizeBody([1, 2])).toEqual({});
  });
});
