import { test, expect } from '@playwright/test';

test.describe('Autenticación', () => {
  test('debe mostrar botón de login cuando no está autenticado', async ({ page }) => {
    await page.goto('/');
    
    await expect(page.locator('h1')).toContainText('Turnaki');
    await expect(page.getByRole('button', { name: /Iniciar sesión/i })).toBeVisible();
  });

  test('debe mostrar el botón y permitir click de login sin errores', async ({ page }) => {
    await page.goto('/');
    const loginButton = page.getByRole('button', { name: /Iniciar sesión/i });
    await expect(loginButton).toBeVisible();
    await loginButton.click({ force: true });
    // No asertamos navegación externa; solo que el click no rompe la UI
    await expect(page.locator('h1')).toContainText('Turnaki');
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
