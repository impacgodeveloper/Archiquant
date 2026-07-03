# ArchiQuant E2E (Playwright)

Covers: registration, login, logout, project creation, drawing upload, quantity
takeoff, BOQ/costing, export, team management — 12 tests across 3 specs.

## Run
```bash
cd e2e
npm install
npm run install-browsers          # one-time: download Chromium
BASE_URL=http://localhost:8080 \
  E2E_SLUG=ipg E2E_EMAIL=adityaram@impacgo.com E2E_PASSWORD=demo1234 \
  npm test
```
`--list` (no browser needed) verifies the suite parses: `npm run list`.

## ⚠️ Flutter renderer caveat (read before running)
Flutter web's default **CanvasKit** renderer paints to a `<canvas>`, so the DOM
has no text/roles and Playwright selectors won't match. To run these E2E tests:

- **Option A (recommended for E2E):** build the app with the **HTML renderer** for
  a test deployment, or
- **Option B:** rely on Flutter's **semantics tree** — `helpers.ts` clicks the
  "Enable accessibility" node and selects by `aria-label`. Coverage depends on
  widgets having semantic labels.

For the most reliable Flutter E2E, also consider Flutter's own
`integration_test` package (drives real widgets, renderer-agnostic). These
Playwright specs are the cross-browser/black-box layer; treat green `--list` +
a live HTML-renderer run as the gate in CI.

## CI
Add a job that builds a test web bundle (HTML renderer), serves it, then runs
`npm test` with `BASE_URL` pointed at it. Artifacts (trace/video/screenshots)
upload on failure (configured in `playwright.config.ts`).
