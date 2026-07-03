#!/usr/bin/env bash
#
# Automated restore DRILL — restores the latest backup into a SCRATCH database
# and asserts the core tables are non-empty. Proves backups are actually
# restorable (a backup you've never restored is not a backup). Non-interactive.
#
# Required env:
#   DRILL_DB_URL   connection string to a THROWAWAY scratch database (NOT prod)
# Optional env:
#   BACKUP_DIR     default: ./backups
#
# Exits non-zero (alertable) if the latest backup is missing or restores empty.

set -euo pipefail
: "${DRILL_DB_URL:?Set DRILL_DB_URL to a scratch (non-prod) database}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"

LATEST="$(ls -t "$BACKUP_DIR"/archiquant-*.sql.gz 2>/dev/null | head -1 || true)"
[ -n "$LATEST" ] || { echo "ERROR: no backups found in $BACKUP_DIR"; exit 1; }

echo "[$(date -u +%FT%TZ)] Drill: restoring $LATEST into scratch DB"
gzip -dc "$LATEST" | psql "$DRILL_DB_URL" -v ON_ERROR_STOP=1 >/dev/null

COMPANIES=$(psql "$DRILL_DB_URL" -At -c "SELECT count(*) FROM companies;")
USERS=$(psql "$DRILL_DB_URL" -At -c "SELECT count(*) FROM users;")
echo "Restored: companies=$COMPANIES users=$USERS"

if [ "$COMPANIES" -lt 1 ] || [ "$USERS" -lt 1 ]; then
  echo "DRILL FAILED: restored database is empty"; exit 1
fi
echo "[$(date -u +%FT%TZ)] DRILL PASSED — backup is restorable."
