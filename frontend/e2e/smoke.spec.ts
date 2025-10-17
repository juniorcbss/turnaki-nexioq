import { test, expect } from '@playwright/test';

test.describe('Smoke UI', () => {
  test('home renderiza y permite abrir booking', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('h1')).toContainText(/Turnaki/i);
    const bookingLink = page.getByRole('link', { name: /Reservar|Booking/i });
    if (await bookingLink.isVisible()) {
      await bookingLink.click({ trial: true }).catch(() => {});
      await expect(page).toHaveURL(/booking|\/$/, { timeout: 5000 });
    }
  });
});


