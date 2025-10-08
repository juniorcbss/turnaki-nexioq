import { test, expect } from '@playwright/test';

test.describe('Autenticación', () => {
  test('debe mostrar botón de login cuando no está autenticado', async ({ page }) => {
    await page.goto('/');
    
    await expect(page.locator('h1')).toContainText('Turnaki');
    await expect(page.getByRole('button', { name: /Iniciar sesión/i })).toBeVisible();
  });

  test('debe construir correctamente la URL de Cognito al hacer login (sin navegar)', async ({ page }) => {
    // Interceptar la navegación a Cognito y capturar la URL
    let capturedUrl = '';
    await page.route('**/oauth2/authorize**', async (route) => {
      capturedUrl = route.request().url();
      await route.abort();
    });

    await page.goto('/');

    const loginButton = page.getByRole('button', { name: /Iniciar sesión/i });
    // Disparar el click y esperar a que el route capture la URL
    await loginButton.click({ force: true });
    await expect.poll(() => capturedUrl, { timeout: 5000 }).not.toBe('');

    // Verificar que la URL generada apunte a Cognito Hosted UI
    expect(capturedUrl).toContain('amazoncognito.com');
    expect(capturedUrl).toContain('/oauth2/authorize');
    expect(capturedUrl).toMatch(/redirect_uri=/);
  });

  test('debe mostrar verificación de API', async ({ page }) => {
    await page.goto('/');
    
    const verifyButton = page.getByRole('button', { name: /Verificar API/i });
    await expect(verifyButton).toBeVisible();
    
    await verifyButton.click();
    
    // Esperar resultado (puede tardar 1-2s)
    await page.waitForSelector('.alert', { timeout: 5000 });
    
    const alert = page.locator('.alert');
    // Debe mostrar success o error
    await expect(alert).toBeVisible();
  });
});
