import { test, expect } from '@playwright/test';
import { login, uniqueSlug } from './helpers';

const SLUG = process.env.E2E_SLUG || 'ipg';
const EMAIL = process.env.E2E_EMAIL || 'adityaram@impacgo.com';
const PASSWORD = process.env.E2E_PASSWORD || 'demo1234';

test.describe('Team management', () => {
  test.beforeEach(async ({ page }) => {
    await login(page, SLUG, EMAIL, PASSWORD);
    await page.goto('/settings');
  });

  test('invite form validates a weak password', async ({ page }) => {
    await page.getByText(/add (team )?member|invite/i).first().click().catch(() => {});
    const email = `${uniqueSlug('teammate')}@example.com`;
    const inputs = page.locator('input');
    await inputs.nth(0).fill(email);
    await inputs.nth(1).fill('123'); // too weak
    await page.getByRole('button', { name: /add|invite/i }).first().click();
    await expect(page.getByText(/at least 8|letter and a number/i)).toBeVisible();
  });

  test('invite a valid team member', async ({ page }) => {
    await page.getByText(/add (team )?member|invite/i).first().click().catch(() => {});
    const email = `${uniqueSlug('teammate')}@example.com`;
    const inputs = page.locator('input');
    await inputs.nth(0).fill(email);
    await inputs.nth(1).fill('Strong1234');
    await page.getByRole('button', { name: /add|invite/i }).first().click();
    await expect(page.getByText(/added|success|user limit/i)).toBeVisible({ timeout: 15_000 });
  });
});
