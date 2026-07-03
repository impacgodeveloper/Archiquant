const { isValidEmail, validatePassword, isValidSlug } = require("../utils/validation");

describe("isValidEmail", () => {
  test("accepts valid", () => {
    expect(isValidEmail("a@b.com")).toBe(true);
    expect(isValidEmail("adityaram@impacgo.com")).toBe(true);
  });
  test("rejects invalid", () => {
    for (const e of ["bad", "a@b", "@b.com", "a b@c.com", "", null, 123]) {
      expect(isValidEmail(e)).toBe(false);
    }
  });
});

describe("validatePassword", () => {
  test("accepts a letter+number, >=8 chars", () => {
    expect(validatePassword("demo1234").ok).toBe(true);
  });
  test("rejects short / letters-only / numbers-only", () => {
    expect(validatePassword("ab1").ok).toBe(false);
    expect(validatePassword("password").ok).toBe(false);
    expect(validatePassword("12345678").ok).toBe(false);
    expect(validatePassword(null).ok).toBe(false);
  });
});

describe("isValidSlug", () => {
  test("accepts/rejects", () => {
    expect(isValidSlug("ipg")).toBe(true);
    expect(isValidSlug("my-company-1")).toBe(true);
    expect(isValidSlug("AB")).toBe(false);
    expect(isValidSlug("has space")).toBe(false);
    expect(isValidSlug("a")).toBe(false);
  });
});
