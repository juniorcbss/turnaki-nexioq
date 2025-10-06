import { test, expect } from '@playwright/test';

test.describe('Mis Citas', () => {
  test('debe requerir autenticación', async ({ page }) => {
    await page.goto('/my-appointments');
    await page.waitForURL(/\/$/, { timeout: 2000 }).catch(() => {});
    expect(page.url()).toMatch(/\/$/);
  });

  test('debe mostrar lista de citas (mock)', async ({ page }) => {
    await page.addInitScript(() => {
      localStorage.setItem('tk_nq_token', 'mock-patient-token');
    });

    await page.goto('/my-appointments');
    
    await expect(page.locator('h1')).toContainText('Mis Citas');
    
    // Con datos mock, debe mostrar 2 citas
    const appointments = page.locator('.appointment-card');
    await expect(appointments).toHaveCount(2, { timeout: 2000 });
  });
});
