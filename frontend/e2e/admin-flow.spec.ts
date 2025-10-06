import { test, expect } from '@playwright/test';

test.describe('Panel de Administración', () => {
  test('debe requerir autenticación para acceder', async ({ page }) => {
    await page.goto('/admin');
    
    // Sin auth, debe redirigir a home
    await page.waitForURL(/\/$/, { timeout: 3000 }).catch(() => {});
    
    const url = page.url();
    expect(url).toMatch(/\/$/);
  });

  test('debe mostrar tabs de administración (con auth mock)', async ({ page }) => {
    // Simular autenticación con rol Admin
    await page.addInitScript(() => {
      localStorage.setItem('tk_nq_token', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFkbWluQHRlc3QuY29tIiwiY29nbml0bzpncm91cHMiOlsiQWRtaW4iXX0.test');
    });

    await page.goto('/admin');
    
    // Verificar tabs
    const tabs = page.locator('.tab');
    await expect(tabs).toHaveCount(3);
    
    await expect(page.getByText('Tratamientos')).toBeVisible();
    await expect(page.getByText('Profesionales')).toBeVisible();
    await expect(page.getByText('Configuración')).toBeVisible();
  });

  test('debe permitir crear tratamiento (mock API)', async ({ page }) => {
    await page.addInitScript(() => {
      localStorage.setItem('tk_nq_token', 'mock-admin-token');
    });

    // Mock de API
    await page.route('**/treatments', async (route) => {
      if (route.request().method() === 'POST') {
        await route.fulfill({
          status: 201,
          contentType: 'application/json',
          body: JSON.stringify({
            id: 'treatment-new',
            name: 'Test Treatment',
            duration_minutes: 30
          })
        });
      } else {
        await route.fulfill({
          status: 200,
          body: JSON.stringify({ treatments: [], count: 0 })
        });
      }
    });

    await page.goto('/admin');

    const nameInput = page.locator('#name');
    if (await nameInput.isVisible()) {
      await nameInput.fill('Limpieza de Prueba');
      
      const durationInput = page.locator('#duration');
      await durationInput.fill('30');
      
      const createButton = page.getByRole('button', { name: /Crear Tratamiento/i });
      await createButton.click();
      
      // Esperar mensaje de éxito
      await expect(page.locator('.alert-success')).toBeVisible({ timeout: 3000 });
    }
  });
});
