# ArchiQuant — Backup & Disaster Recovery Runbook

## Objectives
- **RPO (max data loss):** ≤ 24h via nightly dumps; ≤ 5 min if Supabase PITR is enabled.
- **RTO (max downtime):** ≤ 1h for DB restore + redeploy.

## Backup layers
| Layer | Mechanism | Frequency | Location | Script |
|-------|-----------|-----------|----------|--------|
| DB (logical) | `pg_dump` + gzip | nightly 02:00 | `./backups` (sync off-box!) | `scripts/backup_verify.sh` |
| DB (PITR) | Supabase point-in-time | continuous | Supabase | enable in dashboard |
| Uploads | tarball of `backend/uploads/` | nightly 02:30 | `./backups` (sync off-box!) | `scripts/backup_uploads.sh` |
| Restore drill | restore latest → scratch DB | weekly Sun 03:00 | scratch DB | `scripts/restore_drill.sh` |

> ⚠️ `./backups` on the same VPS disk is **not** durable. Sync it off-box (S3/Backblaze/rclone) — a disk failure must not lose both prod and backups.

## One-time setup
1. `apt-get install postgresql-client` on the VPS.
2. Put secrets in `/etc/archiquant.env` (`SUPABASE_DB_URL=...`) and `/etc/archiquant-drill.env` (`DRILL_DB_URL=...`).
3. `crontab scripts/crontab.example` (after editing paths).
4. Enable **Supabase → Database → Backups → PITR**.
5. Configure off-box sync of `./backups` (add an `rclone copy` line to the backup scripts).

## Recovery procedures

### A. Accidental data loss / bad migration (DB intact, data wrong)
1. Identify a good backup: `ls -t backups/archiquant-*.sql.gz`.
2. If PITR is on, prefer Supabase dashboard → Restore to a timestamp just before the incident.
3. Otherwise: `SUPABASE_DB_URL=... ./scripts/restore_db.sh backups/archiquant-<ts>.sql.gz` (type `RESTORE` to confirm).
4. Re-apply migrations: `psql "$SUPABASE_DB_URL" -f backend/db/migrations/001_rls_indexes_constraints.up.sql`.
5. Verify: `psql "$SUPABASE_DB_URL" -f backend/db/verify_tenant_isolation.sql`.

### B. Full VPS loss
1. Provision a new VPS; install Node 20, Python, PM2, postgresql-client.
2. `git clone` the repo; `cd backend && npm ci`; create `.env` from `.env.example` with **rotated** secrets.
3. DB is in Supabase (separate) — no action unless DB also lost (then do A).
4. Restore uploads: `tar -xzf backups/uploads-<ts>.tar.gz -C backend/`.
5. `pm2 start ecosystem.config.js && pm2 save`; verify `GET /health` and `/ready`.
6. Repoint DNS / nginx to the new host.

### C. Compromised secrets (the V1 leak scenario)
1. Rotate `SUPABASE_SERVICE_KEY` (Supabase dashboard) + `JWT_SECRET` + `JWT_REFRESH_SECRET`.
2. Update `/etc/archiquant.env` and the app `.env`; `pm2 restart all`.
3. Rotating `JWT_SECRET` invalidates all sessions — users simply re-login.

## Verification cadence
- The weekly drill (`restore_drill.sh`) must pass; alert if it exits non-zero.
- Quarterly: perform a **full** procedure B in staging end-to-end.
