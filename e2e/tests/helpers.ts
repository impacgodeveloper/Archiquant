import { Page, expect } from '@playwright/test';

// ⚠️ Flutter web renderer note:
// With the CanvasKit renderer Flutter paints to a <canvas> and the DOM has no
// text/roles, so Playwright can't see widgets. For E2E either:
//   (a) build with the HTML renderer, or
//   (b) enable Flutter's semantics tree (these helpers click the
//       "Enable accessibility" node) and select by aria-label.
// For the most robust Flutter E2E, prefer `integration_test` (see README).

// Turn on Flutter's semantics tree so the accessibility DOM is queryable.
export async function enableFlutterSemantics(page: Page) {
  const enable = page.locator('flt-semantics-placeholder, [aria-label="Enable accessibility"]');
  try {
    await enable.first().click({ timeout: 3000 });
  } catch {
    /* already enabled or HTML renderer — fine */
  }
}

export function uniqueSlug(prefix = 'e2e') {
  // Deterministic-ish unique value; avoids Date.now collisions across workers.
  return `${prefix}-${Math.random().toString(36).slice(2, 8)}`;
}

export async function gotoApp(page: Page, path = '/') {
  await page.goto(path);
  await enableFlutterSemantics(page);
}

export async function login(page: Page, slug: string, email: string, password: string) {
  await gotoApp(page, '/login');
  await page.getByText('Welcome back').waitFor();
  await page.getByText(/Company ID/i).waitFor();
  // Fill by field order (Company ID, Email, Password) — robust to label markup.
  const inputs = page.locator('input');
  await inputs.nth(0).fill(slug);
  await inputs.nth(1).fill(email);
  await inputs.nth(2).fill(password);
  await page.getByRole('button', { name: /sign in/i }).click();
  await expect(page).toHaveURL(/\/$|\/dashboard/);
}
