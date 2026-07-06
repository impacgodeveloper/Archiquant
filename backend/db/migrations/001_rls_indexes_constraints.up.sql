-- ============================================================================
-- ArchiQuant V3 — Phase 1: Database Hardening (UP)
-- RLS tenant isolation + composite indexes + unique constraints.
-- Idempotent: safe to re-run. Wrap in a transaction.
--
-- ⚠️ IMPORTANT — how RLS actually protects you here:
-- The API currently connects with the Supabase SERVICE_ROLE key, which has the
-- BYPASSRLS attribute — RLS policies DO NOT run for it. These policies become
-- real defense-in-depth ONLY when the app connects with a role that is subject
-- to RLS AND sets the tenant GUC per request/transaction, e.g.:
--     SET LOCAL app.current_company_id = '<uuid-from-jwt>';
-- The existing withCompany() helper already issues set_config('app.current_company_id', ...).
-- Until the app stops using service_role for tenant queries, isolation still
-- rests on the explicit .eq('company_id') filters in server.js (now also
-- backed by these indexes). See OBSERVABILITY.md / PRODUCTION_AUDIT_V3.md.
-- ============================================================================

BEGIN;

-- Helper: read the per-request tenant id set via set_config('app.current_company_id', ...).
CREATE OR REPLACE FUNCTION app_current_company_id()
RETURNS uuid
LANGUAGE sql STABLE
AS $$ SELECT NULLIF(current_setting('app.current_company_id', true), '')::uuid $$;

-- ── Enable RLS + tenant-isolation policy on every tenant-scoped table ───────
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'projects','floor_plans','formula_definitions','master_rates',
    'material_configs','material_estimations','structural_elements',
    'company_settings','users'
  ]
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY;', t);
    EXECUTE format('DROP POLICY IF EXISTS tenant_isolation ON %I;', t);
    EXECUTE format($f$
      CREATE POLICY tenant_isolation ON %I
        USING (company_id = app_current_company_id())
        WITH CHECK (company_id = app_current_company_id());
    $f$, t);
  END LOOP;
END $$;

-- companies: a tenant may only see/modify its own row.
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation ON companies;
CREATE POLICY tenant_isolation ON companies
  USING (id = app_current_company_id())
  WITH CHECK (id = app_current_company_id());

-- ── Composite indexes on the hot filter/sort paths (match server.js) ────────
CREATE INDEX IF NOT EXISTS idx_projects_company_created      ON projects            (company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_floorplans_project_company    ON floor_plans         (project_id, company_id);
CREATE INDEX IF NOT EXISTS idx_floorplans_company_status     ON floor_plans         (company_id, ocr_status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_estimations_project_company   ON material_estimations(project_id, company_id);
CREATE INDEX IF NOT EXISTS idx_structural_floorplan_company  ON structural_elements (floor_plan_id, company_id);
CREATE INDEX IF NOT EXISTS idx_master_rates_company_active   ON master_rates        (company_id, active);
CREATE INDEX IF NOT EXISTS idx_master_rates_company_category ON master_rates        (company_id, category);
CREATE INDEX IF NOT EXISTS idx_formulas_company_active       ON formula_definitions (company_id, active);
CREATE INDEX IF NOT EXISTS idx_material_configs_company      ON material_configs    (company_id);
CREATE INDEX IF NOT EXISTS idx_company_settings_company      ON company_settings    (company_id);
CREATE INDEX IF NOT EXISTS idx_users_company_active          ON users               (company_id, active);

-- ── Uniqueness / integrity constraints (guard the register race conditions) ─
CREATE UNIQUE INDEX IF NOT EXISTS uq_companies_slug   ON companies (slug);
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_company_email ON users (company_id, email);

COMMIT;

-- ── OPTIONAL (review before running) — protect tenant data from accidental
-- cascade wipe by switching company FKs from ON DELETE CASCADE to RESTRICT and
-- using a soft-delete flag instead. NOT enabled by default because the current
-- register-rollback path hard-deletes a just-created company.
--   ALTER TABLE companies ADD COLUMN IF NOT EXISTS deleted_at timestamptz;
-- (Then add an app-level guard + filter `deleted_at IS NULL`.)
