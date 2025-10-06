import { test, expect } from '@playwright/test';

test.describe('Autenticación', () => {
  test('debe mostrar botón de login cuando no está autenticado', async ({ page }) => {
    await page.goto('/');
    
    await expect(page.locator('h1')).toContainText('Turnaki');
    await expect(page.getByRole('button', { name: /Iniciar sesión/i })).toBeVisible();
  });

  test('debe redirigir a Cognito Hosted UI al hacer login', async ({ page }) => {
    await page.goto('/');
    
    const loginButton = page.getByRole('button', { name: /Iniciar sesión/i });
    await loginButton.click();
    
    // Debe redirigir a Cognito
    await page.waitForURL(/cognito/, { timeout: 5000 });
    await expect(page.url()).toContain('tk-nq-auth.auth.us-east-1.amazoncognito.com');
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
