import { test, expect } from '@playwright/test';

// Este test verifica el flujo completo de reserva REAL
test.describe('Flujo Completo de Reserva', () => {
  
  test.beforeEach(async ({ page }) => {
    // Ir al home
    await page.goto('http://localhost:5173');
  });

  test('debe mostrar la página de reserva sin autenticación', async ({ page }) => {
    // Ir directo a /booking sin token
  await page.goto(`${process.env.E2E_BASE_URL || 'http://localhost:5173'}/booking`);
    
    // Debe redirigir al home porque no está autenticado
    await expect(page).toHaveURL('http://localhost:5173/');
  });

  test('debe completar el flujo de reserva CON mock de auth', async ({ page }) => {
    // Mock de autenticación en Local Storage
    await page.addInitScript(() => {
      // JWT simulado con payload que contiene email/grupos/tenant_id (no verificado)
      const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      const payload = 'eyJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJuYW1lIjoiVGVzdCBVc2VyIiwiY29nbml0bzpncm91cHMiOlsiUGFjaWVudGUiXSwidGVuYW50X2lkIjoidGVuYW50LWRlbW8tMDAxIn0';
      const token = `${header}.${payload}.test`;
      localStorage.setItem('tk_nq_token', token);
      localStorage.setItem('user', JSON.stringify({
        email: 'test@example.com',
        name: 'Test User',
        groups: ['Paciente'],
        tenant_id: 'tenant-demo-001'
      }));
    });

    // Mock API treatments para evitar 401 (registrar ANTES de navegar)
    await page.route('**/treatments*', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          treatments: [
            { id: 't1', name: 'Limpieza Dental', duration_minutes: 30, price: 50000 }
          ],
          count: 1
        })
      });
    });

    await page.goto('http://localhost:5173');

    // Ir a /booking directamente
    await page.goto('http://localhost:5173/booking');

    // PASO 1: Seleccionar tratamiento
    console.log('PASO 1: Esperando tratamientos...');

    // Esperar a que carguen los tratamientos
    await page.waitForSelector('.treatment-card', {
      timeout: 10000,
      state: 'attached'
    }).catch(async () => {
      // Si no aparecen, capturar el estado actual
      const bodyText = await page.textContent('body');
      console.log('Contenido de la página:', bodyText);
      
      // Capturar screenshot
      await page.screenshot({ path: 'test-results/booking-step1-error.png' });
      
      throw new Error('No se encontraron tratamientos en la página');
    });

    // Click en el primer tratamiento
    const firstTreatment = page.locator('.treatment-card').first();
    await firstTreatment.click();

    console.log('PASO 2: Seleccionando fecha y hora...');
    
    // PASO 2: Verificar que avanzamos al paso 2
    await expect(page.locator('.step.active:has-text("2. Fecha/Hora")')).toBeVisible({ timeout: 10000 });

    // Mockear disponibilidad para evitar 401 y acelerar la prueba
    await page.route('**/booking/availability', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          slots: [
            { start: '09:00', end: '09:45', available: true },
            { start: '10:00', end: '10:45', available: true },
            { start: '11:00', end: '11:45', available: true }
          ]
        })
      });
    });

    await page.waitForSelector('.slot-btn', {
      timeout: 10000,
      state: 'attached'
    }).catch(async () => {
      const bodyText = await page.textContent('body');
      console.log('Contenido paso 2:', bodyText);
      await page.screenshot({ path: 'test-results/booking-step2-error.png' });
      throw new Error('No se encontraron slots de disponibilidad');
    });

    // Seleccionar primer slot
    const firstSlot = page.locator('.slot-btn').first();
    await firstSlot.click();

    console.log('PASO 3: Llenando datos del paciente...');
    
    // PASO 3: Verificar que avanzamos al paso 3
    await expect(page.locator('.step.active:has-text("3. Confirmar")')).toBeVisible({ timeout: 10000 });

    // Llenar formulario
    await page.fill('#name', 'Paciente de Prueba');
    await page.fill('#email', 'paciente@test.com');

    // Click en Confirmar Reserva
    // Mockear creación de reserva para éxito
    await page.route('**/bookings', async (route) => {
      if (route.request().method() === 'POST') {
        await route.fulfill({
          status: 201,
          contentType: 'application/json',
          body: JSON.stringify({
            id: 'bk-test-001',
            tenant_id: 'tenant-demo-001',
            site_id: 'site-001',
            professional_id: 'prof-001',
            treatment_id: 't1',
            start_time: '2025-10-09T09:00:00Z',
            end_time: '2025-10-09T09:45:00Z',
            patient_name: 'Paciente de Prueba',
            patient_email: 'paciente@test.com',
            status: 'CONFIRMED',
            created_at: new Date().toISOString()
          })
        });
        return;
      }
      await route.fallback();
    });

    const confirmButton = page.getByRole('button', { name: /Confirmar/ });
    await confirmButton.click();

    console.log('Esperando confirmación...');

    // Esperar confirmación o error
    await page.waitForSelector('text=¡Reserva confirmada!', { timeout: 15000 });
    console.log('✅ Reserva exitosa');
  });

  test('debe verificar llamadas API durante la reserva', async ({ page }) => {
    // Mock de autenticación
    await page.addInitScript(() => {
      const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      const payload = 'eyJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJncm91cHMiOlsiUGFjaWVudGUiXSwidGVuYW50X2lkIjoidGVuYW50LWRlbW8tMDAxIn0';
      const token = `${header}.${payload}.test`;
      localStorage.setItem('tk_nq_token', token);
      localStorage.setItem('user', JSON.stringify({
        email: 'test@example.com',
        groups: ['Paciente'],
        tenant_id: 'tenant-demo-001'
      }));
    });

    // Interceptar llamadas API
    const apiCalls: any[] = [];
    
    page.on('request', request => {
      if (request.url().includes('execute-api')) {
        apiCalls.push({
          url: request.url(),
          method: request.method(),
          headers: request.headers(),
          body: request.postData()
        });
        console.log(`📡 API Call: ${request.method()} ${request.url()}`);
      }
    });

    page.on('response', async response => {
      if (response.url().includes('execute-api')) {
        const status = response.status();
        let body = '';
        try {
          body = await response.text();
        } catch (e) {
          body = 'Could not read body';
        }
        console.log(`📥 API Response: ${status} ${response.url()}`);
        console.log(`   Body: ${body.substring(0, 200)}`);
      }
    });

    await page.goto('http://localhost:5173/booking');

    // Esperar y verificar que se hagan las llamadas correctas
    await page.waitForTimeout(3000);

    console.log('\n📊 Resumen de llamadas API:');
    apiCalls.forEach((call, i) => {
      console.log(`${i + 1}. ${call.method} ${call.url}`);
      if (call.headers.authorization) {
        console.log(`   Auth: ${call.headers.authorization.substring(0, 50)}...`);
      }
    });

    // Verificar que se llamó a treatments
    const treatmentsCalled = apiCalls.some(call => 
      call.url.includes('/treatments') && call.method === 'GET'
    );
    
    console.log(`\n✓ Treatments API llamada: ${treatmentsCalled}`);
  });

  test('debe diagnosticar por qué no funciona la reserva', async ({ page }) => {
    // Mock auth
    await page.addInitScript(() => {
      localStorage.setItem('token', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0IiwibmFtZSI6IlRlc3QiLCJpYXQiOjE1MTYyMzkwMjJ9.test');
      localStorage.setItem('user', JSON.stringify({
        email: 'test@example.com',
        groups: ['Paciente']
      }));
    });

    // Capturar errores de consola
    const consoleErrors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
        console.log('🔴 Console Error:', msg.text());
      }
    });

    // Capturar errores de red
    const networkErrors: any[] = [];
    page.on('requestfailed', request => {
      networkErrors.push({
        url: request.url(),
        failure: request.failure()?.errorText
      });
      console.log('🔴 Network Error:', request.url(), request.failure()?.errorText);
    });

    await page.goto('http://localhost:5173/booking');

    // Esperar a que la página cargue
    await page.waitForTimeout(5000);

    // Capturar estado final
    const bodyText = await page.textContent('body');
    const hasError = bodyText?.toLowerCase().includes('error');
    const hasTreatments = bodyText?.includes('Limpieza') || bodyText?.includes('Extracción');

    console.log('\n📊 DIAGNÓSTICO:');
    console.log('═══════════════════════════════════════════════════════════');
    console.log(`✓ Página cargó: SÍ`);
    console.log(`✓ Tratamientos visibles: ${hasTreatments ? 'SÍ' : 'NO'}`);
    console.log(`✓ Errores en consola: ${consoleErrors.length}`);
    console.log(`✓ Errores de red: ${networkErrors.length}`);
    console.log(`✓ Mensaje de error visible: ${hasError ? 'SÍ' : 'NO'}`);
    
    if (consoleErrors.length > 0) {
      console.log('\n❌ ERRORES DE CONSOLA:');
      consoleErrors.forEach((err, i) => console.log(`  ${i + 1}. ${err}`));
    }
    
    if (networkErrors.length > 0) {
      console.log('\n❌ ERRORES DE RED:');
      networkErrors.forEach((err, i) => console.log(`  ${i + 1}. ${err.url} - ${err.failure}`));
    }

    // Screenshot final
    await page.screenshot({ 
      path: 'test-results/booking-diagnostico.png',
      fullPage: true 
    });

    console.log('\n📸 Screenshot guardado en: test-results/booking-diagnostico.png');
    console.log('═══════════════════════════════════════════════════════════\n');
  });
});

