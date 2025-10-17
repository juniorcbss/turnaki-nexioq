import { test, expect } from '@playwright/test';

// Ejecuta login real contra Cognito si hay credenciales
const hasCreds = !!process.env.E2E_USER_EMAIL && !!process.env.E2E_USER_PASSWORD;

test.describe(hasCreds ? 'Login real Cognito' : 'Login real Cognito (skip)', () => {
  if (!hasCreds) {
    test.skip(true, 'Requiere E2E_USER_EMAIL/PASSWORD');
  }

  test('debe autenticar y volver a la app con token', async ({ page }) => {
    await page.goto('/');

    const loginButton = page.getByRole('button', { name: /Iniciar sesión/i });
    await expect(loginButton).toBeVisible();
    await loginButton.click();

    // Redirección al Hosted UI de Cognito
    await expect(page).toHaveURL(/amazoncognito\.com|cognito/);

    const email = process.env.E2E_USER_EMAIL as string;
    const password = process.env.E2E_USER_PASSWORD as string;

    // Selectores robustos (diferentes plantillas del Hosted UI)
    const userSelector = '#signInFormUsername, input[name="username"], input#username, input[type="email"]';
    const passSelector = '#signInFormPassword, input[name="password"], input#password, input[type="password"]';
    const submitSelector = '#signInFormSubmitButton, button[type="submit"], button:has-text("Sign in"), button:has-text("Iniciar sesión")';

    await page.locator(userSelector).first().fill(email);
    await page.locator(passSelector).first().fill(password);
    await page.locator(submitSelector).first().click();

    // Debe volver a /auth/callback y luego home
    await page.waitForURL(/auth\/callback|\/$/, { timeout: 30000 });
    await page.waitForLoadState('networkidle');

    // Token en localStorage
    const token = await page.evaluate(() => localStorage.getItem('tk_nq_token'));
    expect(token).toBeTruthy();

    // Acceder a página protegida
    await page.goto('/booking');
    await expect(page).toHaveURL(/booking/);
  });
});


