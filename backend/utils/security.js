// Pure, side-effect-free security helpers. Kept in their own module so they can
// be unit-tested without booting the server / Supabase / env.

// Safe arithmetic evaluator — replaces eval() for company-editable formula
// expressions. Only digits, whitespace, '.', and + - * / ( ) are permitted;
// anything else (identifiers, calls, require, process…) returns the fallback.
function safeArith(expr, fallback) {
  const s = String(expr ?? "").trim();
  if (!s || !/^[\d\s.+\-*/()]+$/.test(s)) return fallback;
  try {
    // Input is regex-restricted to arithmetic — no identifiers/calls possible.
    // eslint-disable-next-line no-new-func
    const v = Function(`"use strict";return(${s});`)();
    return Number.isFinite(v) ? v : fallback;
  } catch {
    return fallback;
  }
}

// Strip fields a client must never set on insert/update (tenant key, identity,
// timestamps). Prevents mass-assignment / cross-tenant writes via ...req.body.
function sanitizeBody(body) {
  if (!body || typeof body !== "object" || Array.isArray(body)) return {};
  const { id, company_id, created_at, updated_at, ...rest } = body;
  return rest;
}

module.exports = { safeArith, sanitizeBody };
