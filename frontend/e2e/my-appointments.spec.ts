import { test, expect } from '@playwright/test';

test.describe('Mis Citas', () => {
  test('debe requerir autenticación', async ({ page }) => {
    await page.goto('/my-appointments');
    await page.waitForURL(/\/$/, { timeout: 2000 }).catch(() => {});
    expect(page.url()).toMatch(/\/$/);
  });

  test('debe mostrar lista de citas (mock)', async ({ page }) => {
    await page.addInitScript(() => {
      const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      const payload = 'eyJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJncm91cHMiOlsiUGFjaWVudGUiXSwidGVuYW50X2lkIjoidGVuYW50LWRlbW8tMDAxIn0';
      localStorage.setItem('tk_nq_token', `${header}.${payload}.test`);
    });

    await page.route('**/bookings*', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          bookings: [
            { id: 'b1', start_time: '2025-10-01T09:00:00Z', professional_id: 'p1', status: 'confirmed' },
            { id: 'b2', start_time: '2025-10-02T10:00:00Z', professional_id: 'p2', status: 'confirmed' }
          ]
        })
      });
    });

    await page.goto('/my-appointments');
    
    await expect(page.locator('h1')).toContainText('Mis Citas');
    
    // Con datos mock, debe mostrar 2 citas
    const appointments = page.locator('.appointment-card');
    await expect(appointments).toHaveCount(2, { timeout: 5000 });
  });
});
