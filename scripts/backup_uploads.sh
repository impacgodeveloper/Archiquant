#!/usr/bin/env bash
#
# Off-box backup of uploaded floor plans (backend/uploads/), which otherwise
# live only on the single VPS disk. Creates a dated tarball; sync the BACKUP_DIR
# to object storage (S3/Backblaze/rclone) for true durability.
#
# Optional env:
#   UPLOADS_DIR    default: ./backend/uploads
#   BACKUP_DIR     default: ./backups
#   RETENTION_DAYS default: 30
#
# Cron:  30 2 * * *  cd /path/to/app && ./scripts/backup_uploads.sh >> /var/log/archiquant-uploads.log 2>&1

set -euo pipefail
UPLOADS_DIR="${UPLOADS_DIR:-./backend/uploads}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

[ -d "$UPLOADS_DIR" ] || { echo "Nothing to back up: $UPLOADS_DIR does not exist"; exit 0; }
mkdir -p "$BACKUP_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="$BACKUP_DIR/uploads-$STAMP.tar.gz"

tar -czf "$ARCHIVE" -C "$(dirname "$UPLOADS_DIR")" "$(basename "$UPLOADS_DIR")"
COUNT=$(find "$UPLOADS_DIR" -type f | wc -l | tr -d ' ')
echo "[$(date -u +%FT%TZ)] Archived $COUNT files → $ARCHIVE"

# TODO: push off-box, e.g.  rclone copy "$ARCHIVE" remote:archiquant-backups/

find "$BACKUP_DIR" -name 'uploads-*.tar.gz' -mtime +"$RETENTION_DAYS" -delete
echo "Pruned upload archives older than ${RETENTION_DAYS} days."
