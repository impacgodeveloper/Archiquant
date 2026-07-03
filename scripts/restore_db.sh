#!/usr/bin/env bash
#
# Restore a database from a backup produced by backup_verify.sh.
# DESTRUCTIVE: overwrites the target database. Requires explicit confirmation.
#
# Required env:
#   SUPABASE_DB_URL   target Postgres connection string
# Args:
#   $1                path to the .sql.gz dump to restore
#
# Usage:  SUPABASE_DB_URL=... ./scripts/restore_db.sh ./backups/archiquant-YYYYMMDD-HHMMSS.sql.gz

set -euo pipefail
: "${SUPABASE_DB_URL:?Set SUPABASE_DB_URL to the target Postgres connection string}"
DUMP="${1:?Usage: restore_db.sh <dump.sql.gz>}"

[ -f "$DUMP" ] || { echo "ERROR: dump not found: $DUMP"; exit 1; }
command -v psql >/dev/null || { echo "ERROR: psql not installed"; exit 1; }

echo "================ RESTORE (DESTRUCTIVE) ================"
echo "Dump  : $DUMP"
echo "Target: ${SUPABASE_DB_URL%%@*}@***"
read -r -p "Type 'RESTORE' to overwrite the target database: " CONFIRM
[ "$CONFIRM" = "RESTORE" ] || { echo "Aborted."; exit 1; }

echo "[$(date -u +%FT%TZ)] Restoring…"
gzip -dc "$DUMP" | psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1

# ── Post-restore sanity check ──
echo "Verifying restored row counts:"
psql "$SUPABASE_DB_URL" -At -c "
  SELECT 'companies='||count(*) FROM companies
  UNION ALL SELECT 'users='||count(*) FROM users
  UNION ALL SELECT 'projects='||count(*) FROM projects
  UNION ALL SELECT 'master_rates='||count(*) FROM master_rates;"

echo "[$(date -u +%FT%TZ)] Restore complete. Re-apply migrations if needed:"
echo "  psql \"\$SUPABASE_DB_URL\" -f backend/db/migrations/001_rls_indexes_constraints.up.sql"
