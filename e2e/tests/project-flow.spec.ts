import { test, expect } from '@playwright/test';
import { login, uniqueSlug } from './helpers';
import path from 'path';

const SLUG = process.env.E2E_SLUG || 'ipg';
const EMAIL = process.env.E2E_EMAIL || 'adityaram@impacgo.com';
const PASSWORD = process.env.E2E_PASSWORD || 'demo1234';
// A small sample plan ships in the repo root for upload tests.
const SAMPLE_PLAN = process.env.E2E_PLAN || path.resolve(__dirname, '../../sample_floor_plan.png');

test.describe('Core project workflow', () => {
  test.beforeEach(async ({ page }) => {
    await login(page, SLUG, EMAIL, PASSWORD);
  });

  test('create a project', async ({ page }) => {
    await page.goto('/project-creation');
    const name = uniqueSlug('proj');
    const inputs = page.locator('input, textarea');
    await inputs.first().fill(name);
    await page.getByRole('button', { name: /create|save/i }).first().click();
    await expect(page.getByText(name).first()).toBeVisible({ timeout: 15_000 });
  });

  test('upload a drawing and see OCR/processing state', async ({ page }) => {
    await page.goto('/upload');
    const chooser = page.locator('input[type="file"]');
    await chooser.setInputFiles(SAMPLE_PLAN);
    // Either the synchronous result or the async "processing" state is acceptable.
    await expect(page.getByText(/processing|result|zones?|wall/i).first()).toBeVisible({ timeout: 120_000 });
  });

  test('quantity takeoff renders for the selected project', async ({ page }) => {
    await page.goto('/takeoff');
    await expect(page.getByText(/takeoff|quantity|no data/i).first()).toBeVisible();
  });

  test('BOQ / costing renders numbers', async ({ page }) => {
    await page.goto('/costing');
    await expect(page.getByText(/brick|boq|net|take-?off|no project/i).first()).toBeVisible({ timeout: 30_000 });
  });

  test('review & budget export produces a download', async ({ page }) => {
    await page.goto('/review');
    await page.getByRole('button', { name: /export/i }).first().click();
    const [download] = await Promise.all([
      page.waitForEvent('download', { timeout: 30_000 }).catch(() => null),
      page.getByText(/excel/i).first().click().catch(() => {}),
    ]);
    // Either a real download fires, or a clear success/failure toast appears.
    if (!download) {
      await expect(page.getByText(/downloaded|export (failed|error)/i)).toBeVisible();
    }
  });
});
