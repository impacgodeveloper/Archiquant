#!/usr/bin/env bash
#
# Supabase / Postgres backup + verification.
# Takes a logical dump, gzips it, and verifies the archive is non-empty and
# contains the expected tenant tables. Intended to run nightly via cron on the
# VPS (or any host with network access to the database).
#
# Required env:
#   SUPABASE_DB_URL   postgres connection string (Project Settings → Database →
#                     Connection string → URI). e.g.
#                     postgres://postgres:<pwd>@db.<ref>.supabase.co:5432/postgres
# Optional env:
#   BACKUP_DIR        where to write dumps (default: ./backups)
#   RETENTION_DAYS    delete dumps older than this (default: 14)
#
# Usage:  SUPABASE_DB_URL=... ./scripts/backup_verify.sh
# Cron :  0 2 * * *  cd /path/to/app && SUPABASE_DB_URL=... ./scripts/backup_verify.sh >> /var/log/archiquant-backup.log 2>&1

set -euo pipefail

: "${SUPABASE_DB_URL:?Set SUPABASE_DB_URL to the Postgres connection string}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
EXPECTED_TABLES=("companies" "users" "projects" "master_rates" "floor_plans")

mkdir -p "$BACKUP_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
DUMP="$BACKUP_DIR/archiquant-$STAMP.sql.gz"

command -v pg_dump >/dev/null || { echo "ERROR: pg_dump not installed (apt-get install postgresql-client)"; exit 1; }

echo "[$(date -u +%FT%TZ)] Dumping database → $DUMP"
pg_dump "$SUPABASE_DB_URL" --no-owner --no-privileges | gzip > "$DUMP"

# ── Verify: archive exists and is a reasonable size ──
SIZE=$(wc -c < "$DUMP")
if [ "$SIZE" -lt 1024 ]; then
  echo "ERROR: dump is suspiciously small ($SIZE bytes) — backup FAILED"
  exit 1
fi

# ── Verify: expected tables are present in the dump ──
MISSING=0
for t in "${EXPECTED_TABLES[@]}"; do
  if ! gzip -dc "$DUMP" | grep -q "CREATE TABLE.*\b$t\b"; then
    echo "WARNING: expected table '$t' not found in dump"
    MISSING=1
  fi
done
[ "$MISSING" -eq 0 ] || { echo "ERROR: one or more expected tables missing — verify FAILED"; exit 1; }

echo "[$(date -u +%FT%TZ)] OK — backup verified ($SIZE bytes, all tenant tables present)"

# ── Retention: prune old dumps ──
find "$BACKUP_DIR" -name 'archiquant-*.sql.gz' -mtime +"$RETENTION_DAYS" -delete
echo "Pruned dumps older than ${RETENTION_DAYS} days."
