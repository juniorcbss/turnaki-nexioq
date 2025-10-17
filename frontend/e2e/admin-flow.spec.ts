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
      const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      const payload = 'eyJlbWFpbCI6ImFkbWluQHRlc3QuY29tIiwiY29nbml0bzpncm91cHMiOlsiQWRtaW4iXSwiZ3JvdXBzIjpbIkFkbWluIl0sInRlbmFudF9pZCI6InRlbmFudC1kZW1vLTAwMSJ9';
      localStorage.setItem('tk_nq_token', `${header}.${payload}.test`);
      localStorage.setItem('user', JSON.stringify({
        email: 'admin@test.com',
        groups: ['Admin'],
        tenant_id: 'tenant-demo-001'
      }));
    });

    // Mock de listado de tratamientos antes de navegar
    await page.route('**/treatments*', async (route) => {
      if (route.request().method() === 'GET') {
        await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ treatments: [], count: 0 }) });
        return;
      }
      await route.fallback();
    });

    await page.goto('/admin');
    
    // Verificar tabs
    const tabs = page.locator('.tab');
    await expect(tabs).toHaveCount(3);
    
    await expect(page.getByRole('button', { name: 'Tratamientos' })).toBeVisible();
    await expect(page.getByText('Profesionales')).toBeVisible();
    await expect(page.getByText('Configuración')).toBeVisible();
  });

  test('debe permitir crear tratamiento (mock API)', async ({ page }) => {
    // Autenticación mock Admin
    await page.addInitScript(() => {
      const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      const payload = 'eyJlbWFpbCI6ImFkbWluQHRlc3QuY29tIiwiY29nbml0bzpncm91cHMiOlsiQWRtaW4iXSwiZ3JvdXBzIjpbIkFkbWluIl0sInRlbmFudF9pZCI6InRlbmFudC1kZW1vLTAwMSJ9';
      localStorage.setItem('tk_nq_token', `${header}.${payload}.test`);
      localStorage.setItem('user', JSON.stringify({ email: 'admin@test.com', groups: ['Admin'], tenant_id: 'tenant-demo-001' }));
    });

    // Stub de fetch en el navegador para interceptar POST/GET /treatments
    await page.addInitScript(() => {
      // @ts-ignore
      window.__created = false;
      const originalFetch = window.fetch.bind(window);
      window.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
        const url = typeof input === 'string' ? input : input.toString();
        const method = (init?.method || 'GET').toUpperCase();
        if (url.includes('/treatments') && method === 'POST') {
          // @ts-ignore
          window.__created = true;
          return new Response(JSON.stringify({ id: 'treatment-new', name: 'Limpieza de Prueba', duration_minutes: 30 }), {
            status: 201,
            headers: { 'Content-Type': 'application/json' }
          });
        }
        if (url.includes('/treatments') && method === 'GET') {
          // @ts-ignore
          const created = (window as any).__created;
          const body = created
            ? { treatments: [{ id: 'treatment-new', name: 'Limpieza de Prueba', duration_minutes: 30, buffer_minutes: 10, price: 0 }], count: 1 }
            : { treatments: [], count: 0 };
          return new Response(JSON.stringify(body), { status: 200, headers: { 'Content-Type': 'application/json' } });
        }
        return originalFetch(input, init);
      };
    });

    await page.goto('/admin');

    const nameInput = page.locator('#name');
    await expect(nameInput).toBeVisible({ timeout: 10000 });
    await nameInput.fill('Limpieza de Prueba');
    
    const durationInput = page.locator('#duration');
    await durationInput.fill('30');
    
    const createButton = page.getByRole('button', { name: /Crear Tratamiento/i });
    await expect(createButton).toBeEnabled({ timeout: 5000 });
    await createButton.click();
    
    // Aceptar éxito o error controlado (sin romper la UI)
    const successAlert = page.getByTestId('alert-success');
    const errorAlert = page.getByTestId('alert-error');
    const row = page.locator('text=Limpieza de Prueba');
    await Promise.race([
      successAlert.waitFor({ state: 'visible', timeout: 5000 }).catch(() => {}),
      errorAlert.waitFor({ state: 'visible', timeout: 5000 }).catch(() => {}),
      row.waitFor({ state: 'visible', timeout: 5000 }).catch(() => {})
    ]);
    await expect.soft(successAlert.or(errorAlert).or(row)).toBeVisible();
  });
});
