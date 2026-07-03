-- ============================================================================
-- ArchiQuant V3 — Tenant Isolation Verification
-- Run against a database that has the migration applied AND is connected with
-- a role subject to RLS (NOT service_role). Proves cross-tenant access fails.
--
-- Usage (psql):  psql "$SUPABASE_DB_URL" -f verify_tenant_isolation.sql
-- Expected: section A returns only company A's rows; section B returns ZERO of
-- company A's rows; the INSERT in section C is rejected by the WITH CHECK clause.
-- ============================================================================

-- 1) RLS is enabled + forced on every tenant table.
SELECT relname,
       relrowsecurity  AS rls_enabled,
       relforcerowsecurity AS rls_forced
FROM pg_class
WHERE relname IN ('projects','floor_plans','formula_definitions','master_rates',
                  'material_configs','material_estimations','structural_elements',
                  'company_settings','users','companies')
ORDER BY relname;
-- EXPECT: rls_enabled = t and rls_forced = t for all rows.

-- 2) Every tenant table has a tenant_isolation policy.
SELECT tablename, policyname FROM pg_policies
WHERE policyname = 'tenant_isolation' ORDER BY tablename;

-- 3) The hot-path indexes exist.
SELECT indexname FROM pg_indexes
WHERE indexname LIKE 'idx_%' OR indexname LIKE 'uq_%'
ORDER BY indexname;

-- 4) Functional check — replace the UUIDs with two real company ids.
--    Section A: acting as company A, you see A's projects.
-- SET app.current_company_id = '<COMPANY_A_UUID>';
-- SELECT count(*) AS visible_to_a FROM projects;          -- > 0

--    Section B: acting as company B, A's projects are invisible.
-- SET app.current_company_id = '<COMPANY_B_UUID>';
-- SELECT count(*) AS a_rows_visible_to_b FROM projects
--   WHERE company_id = '<COMPANY_A_UUID>';                -- EXPECT 0

--    Section C: cross-tenant write is rejected by WITH CHECK.
-- SET app.current_company_id = '<COMPANY_B_UUID>';
-- INSERT INTO projects (company_id, name) VALUES ('<COMPANY_A_UUID>', 'evil');
--   -- EXPECT: ERROR new row violates row-level security policy
