import { test, expect } from '@playwright/test';
import { gotoApp, login, uniqueSlug } from './helpers';

const SLUG = process.env.E2E_SLUG || 'ipg';
const EMAIL = process.env.E2E_EMAIL || 'adityaram@impacgo.com';
const PASSWORD = process.env.E2E_PASSWORD || 'demo1234';

test.describe('Authentication', () => {
  test('app boots to the login screen', async ({ page }) => {
    await gotoApp(page, '/login');
    await expect(page.getByText('Welcome back')).toBeVisible();
  });

  test('rejects invalid email format', async ({ page }) => {
    await gotoApp(page, '/login');
    const inputs = page.locator('input');
    await inputs.nth(0).fill('ipg');
    await inputs.nth(1).fill('not-an-email');
    await inputs.nth(2).fill('whatever1');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page.getByText(/valid email/i)).toBeVisible();
  });

  test('rejects bad credentials', async ({ page }) => {
    await gotoApp(page, '/login');
    const inputs = page.locator('input');
    await inputs.nth(0).fill('ipg');
    await inputs.nth(1).fill('nobody@example.com');
    await inputs.nth(2).fill('wrongpass1');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page.getByText(/invalid credentials|failed/i)).toBeVisible();
  });

  test('registration page is reachable', async ({ page }) => {
    await gotoApp(page, '/register');
    await expect(page.getByText(/create|company/i).first()).toBeVisible();
  });

  test('valid login lands on the dashboard, logout returns to login', async ({ page }) => {
    await login(page, SLUG, EMAIL, PASSWORD);
    await expect(page.getByText(/dashboard/i).first()).toBeVisible();
    await page.getByText(/logout/i).click();
    await expect(page).toHaveURL(/\/login/);
  });
});
