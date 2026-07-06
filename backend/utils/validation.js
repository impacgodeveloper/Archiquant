// Input validators — pure functions, unit-testable in isolation.

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

function isValidEmail(email) {
  return typeof email === "string" && EMAIL_RE.test(email.trim()) && email.length <= 254;
}

// Company-ID / slug: lowercase alphanumeric + hyphen, 3-40 chars.
function isValidSlug(slug) {
  return typeof slug === "string" && /^[a-z0-9-]{3,40}$/.test(slug);
}

// Password policy: >=8 chars, at least one letter and one number.
// Returns { ok, message }.
function validatePassword(password) {
  if (typeof password !== "string" || password.length < 8) {
    return { ok: false, message: "Password must be at least 8 characters" };
  }
  if (password.length > 128) {
    return { ok: false, message: "Password is too long" };
  }
  if (!/[A-Za-z]/.test(password) || !/[0-9]/.test(password)) {
    return { ok: false, message: "Password must contain a letter and a number" };
  }
  return { ok: true, message: "" };
}

module.exports = { isValidEmail, isValidSlug, validatePassword, EMAIL_RE };
