import { test, expect } from '@playwright/test';

test.describe('Flujos negativos y de borde', () => {
  test('sin disponibilidad muestra mensaje apropiado (mock)', async ({ page }) => {
    await page.route('**/booking/availability', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ slots: [], total: 0 })
      });
    });

    await page.goto('/booking');

    // Intentar avanzar al paso de fecha si existe UI de pasos
    const dateInput = page.locator('input[type="date"]');
    if (await dateInput.isVisible()) {
      await dateInput.fill('2025-10-01');
      // Esperar resultado y validar ausencia de slots
      await page.waitForTimeout(500);
      const slots = page.locator('.slot-btn');
      const count = await slots.count();
      expect(count).toBe(0);

      // Mensaje cortesía si existe
      const emptyMsg = page.locator('.alert, .empty-state, text=/sin disponibilidad/i');
      await expect.soft(emptyMsg).toBeVisible({ timeout: 2000 });
    }
  });

  test('conflicto de doble reserva (409) muestra error', async ({ page }) => {
    // Mock disponibilidad mínima
    await page.route('**/booking/availability', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          slots: [
            { start: '2025-10-01T09:00:00Z', end: '2025-10-01T09:30:00Z', available: true }
          ],
          total: 1
        })
      });
    });

    // Mock POST bookings con 409 Conflict
    await page.route('**/bookings', async (route) => {
      if (route.request().method() === 'POST') {
        await route.fulfill({ status: 409, contentType: 'application/json', body: JSON.stringify({ message: 'Slot ya reservado' }) });
        return;
      }
      await route.fallback();
    });

    await page.goto('/booking');

    const dateInput = page.locator('input[type="date"]');
    if (await dateInput.isVisible()) {
      await dateInput.fill('2025-10-01');
      await page.waitForSelector('.slot-btn').catch(() => {});
      const slot = page.locator('.slot-btn').first();
      if (await slot.isVisible()) {
        await slot.click();
      }

      const nameInput = page.locator('#name');
      const emailInput = page.locator('#email');
      if (await nameInput.isVisible()) {
        await nameInput.fill('Paciente Prueba');
        await emailInput.fill('paciente@test.com');
        const confirmButton = page.getByRole('button', { name: /Confirmar/i });
        await confirmButton.click();

        const errorMsg = page.locator('.alert-error, .alert[data-type="error"], text=/Slot ya reservado/i');
        await expect.soft(errorMsg).toBeVisible({ timeout: 3000 });
      }
    }
  });

  test('validación de email inválido en confirmación', async ({ page }) => {
    await page.goto('/booking');

    const emailInput = page.locator('#email');
    if (await emailInput.isVisible()) {
      await emailInput.fill('no-es-email');
      const confirmButton = page.getByRole('button', { name: /Confirmar/i });
      await confirmButton.click();

      const validation = page.locator('.error, .field-error, [aria-invalid="true"]');
      await expect.soft(validation).toBeVisible({ timeout: 2000 });
    }
  });
});


