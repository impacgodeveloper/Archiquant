-- ============================================================================
-- ArchiQuant V3 — Phase 1: Database Hardening (DOWN / ROLLBACK)
-- Reverses 001_rls_indexes_constraints.up.sql. Idempotent.
-- ============================================================================

BEGIN;

-- Drop tenant-isolation policies + disable RLS.
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'projects','floor_plans','formula_definitions','master_rates',
    'material_configs','material_estimations','structural_elements',
    'company_settings','users','companies'
  ]
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS tenant_isolation ON %I;', t);
    EXECUTE format('ALTER TABLE %I NO FORCE ROW LEVEL SECURITY;', t);
    EXECUTE format('ALTER TABLE %I DISABLE ROW LEVEL SECURITY;', t);
  END LOOP;
END $$;

DROP FUNCTION IF EXISTS app_current_company_id();

-- Drop indexes.
DROP INDEX IF EXISTS idx_projects_company_created;
DROP INDEX IF EXISTS idx_floorplans_project_company;
DROP INDEX IF EXISTS idx_floorplans_company_status;
DROP INDEX IF EXISTS idx_estimations_project_company;
DROP INDEX IF EXISTS idx_structural_floorplan_company;
DROP INDEX IF EXISTS idx_master_rates_company_active;
DROP INDEX IF EXISTS idx_master_rates_company_category;
DROP INDEX IF EXISTS idx_formulas_company_active;
DROP INDEX IF EXISTS idx_material_configs_company;
DROP INDEX IF EXISTS idx_company_settings_company;
DROP INDEX IF EXISTS idx_users_company_active;

-- Drop unique constraints/indexes.
DROP INDEX IF EXISTS uq_companies_slug;
DROP INDEX IF EXISTS uq_users_company_email;

COMMIT;
