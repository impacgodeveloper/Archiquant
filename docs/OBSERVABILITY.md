# ArchiQuant — Observability & Operations

## What's instrumented (code)
| Concern | Mechanism | Where |
|---------|-----------|-------|
| Structured logs | `pino` JSON logs, level via `LOG_LEVEL` | `server.js` |
| Request tracing | `pino-http` assigns `req.id`; echoed as `X-Request-Id` response header; honors inbound `X-Request-Id` | `server.js` |
| Error tracking | `@sentry/node` (backend) + `sentry_flutter` (frontend), both gated by DSN | `server.js`, `main.dart` |
| Liveness | `GET /health` → 200 + uptime | `server.js` |
| Readiness | `GET /ready` → 200 if DB reachable, else 503 | `server.js` |
| Queue health | BullMQ metrics (when `OCR_ASYNC=true`) | `services/ocrQueue.js` |

### Log ↔ error correlation
Every request gets an id; it's in every pino log line for that request and in the
`X-Request-Id` response header. Sentry events include the request context. To
trace an incident: get the `X-Request-Id` from the client/response → grep logs →
cross-reference the Sentry issue.

## Activation checklist
- [ ] Set `SENTRY_DSN` (backend env) and build frontend with `--dart-define=SENTRY_DSN=...`.
- [ ] Ship logs off-box: `pm2 install pm2-logrotate` + forward `~/.pm2/logs` to a
      log service (Better Stack / Loki / CloudWatch).
- [ ] Point an external uptime monitor at `https://archiquant.in/health` and `/ready`.

## Recommended dashboards
1. **API health:** request rate, p50/p95/p99 latency, 4xx vs 5xx rate, by route.
2. **Auth:** login success/fail rate, `429` rate on `/auth/*` (brute-force signal),
   refresh-token usage.
3. **OCR pipeline:** queue depth, jobs completed/failed/sec, avg job duration,
   worker count, retry rate.
4. **Database:** connection count, slow-query log, index hit rate, table sizes.
5. **Errors:** Sentry issues by frequency + new-issue rate, top error routes.

## Recommended alerts (page vs notify)
| Severity | Condition | Action |
|----------|-----------|--------|
| 🔴 Page | `/health` or `/ready` failing > 2 min | on-call |
| 🔴 Page | 5xx rate > 5% over 5 min | on-call |
| 🔴 Page | DB connections > 90% of pool | on-call |
| 🟠 Notify | OCR queue depth > 200 or failed-job rate > 10% | Slack |
| 🟠 Notify | `429` spike on `/auth/login` (credential stuffing) | Slack + security |
| 🟠 Notify | weekly restore drill (`restore_drill.sh`) exits non-zero | Slack |
| 🟡 Watch | p95 latency > 1s for 15 min | dashboard |
| 🟡 Watch | new Sentry issue introduced post-deploy | dashboard |

## Operational runbooks

### API is down (`/health` failing)
1. `pm2 status` / `pm2 logs archiquant-api --lines 200`.
2. If crash-looping: check the last deploy; `pm2 restart archiquant-api`; if a bad
   release, redeploy the previous tag.
3. If `/health` ok but `/ready` 503 → DB unreachable: check Supabase status +
   `SUPABASE_*` env; verify network/egress.

### High 5xx after deploy
1. Grep logs for the spiking route + an `X-Request-Id`; open the matching Sentry issue.
2. Roll back: redeploy previous release (`pm2 reload` the prior dir) / revert gh-pages.

### OCR backlog growing (async mode)
1. Check queue depth + worker count; `pm2 scale archiquant-ocr-worker +2`.
2. Inspect failed jobs in Redis/BullMQ; if EasyOCR sidecar is down, restart
   `archiquant-ocr`; failed plans show `ocr_status="failed"` to users.

### Suspected credential stuffing (`/auth` 429 spike)
1. Confirm via rate-limit logs; identify source IPs.
2. Tighten `authLimiter` / add IP block at nginx; force-rotate affected accounts.

### Data incident
→ see `RECOVERY.md` (restore procedures + DR).
