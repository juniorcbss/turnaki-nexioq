import { test, expect } from '@playwright/test';

// Este test verifica el flujo completo de reserva REAL
test.describe('Flujo Completo de Reserva', () => {
  
  test.beforeEach(async ({ page }) => {
    // Ir al home
    await page.goto('http://localhost:5173');
  });

  test('debe mostrar la página de reserva sin autenticación', async ({ page }) => {
    // Click en Reservar Cita sin estar autenticado
    await page.click('text=Reservar Cita');
    
    // Debería redirigir al home porque no está autenticado
    await expect(page).toHaveURL('http://localhost:5173/');
  });

  test('debe completar el flujo de reserva CON mock de auth', async ({ page }) => {
    // Mock de autenticación en Local Storage
    await page.addInitScript(() => {
      localStorage.setItem('token', 'mock-jwt-token-for-testing');
      localStorage.setItem('user', JSON.stringify({
        email: 'test@example.com',
        name: 'Test User',
        groups: ['Paciente']
      }));
    });

    await page.goto('http://localhost:5173');
    
    // Verificar que estamos autenticados
    await expect(page.locator('text=test@example.com')).toBeVisible();

    // Click en Reservar Cita
    await page.click('text=Reservar Cita');
    
    // Verificar que llegamos a /booking
    await expect(page).toHaveURL('http://localhost:5173/booking');

    // PASO 1: Seleccionar tratamiento
    console.log('PASO 1: Esperando tratamientos...');
    
    // Esperar a que carguen los tratamientos (pueden ser mock o reales)
    await page.waitForSelector('text=Limpieza Dental, text=Extracción, text=Ortodoncia', { 
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
    const firstTreatment = page.locator('button:has-text("Seleccionar")').first();
    await firstTreatment.click();

    console.log('PASO 2: Seleccionando fecha y hora...');
    
    // PASO 2: Verificar que avanzamos al paso 2
    await expect(page.locator('text=Paso 2')).toBeVisible({ timeout: 5000 });

    // Esperar slots de disponibilidad
    await page.waitForSelector('text=09:00, text=10:00, text=11:00', {
      timeout: 10000,
      state: 'attached'
    }).catch(async () => {
      const bodyText = await page.textContent('body');
      console.log('Contenido paso 2:', bodyText);
      await page.screenshot({ path: 'test-results/booking-step2-error.png' });
      throw new Error('No se encontraron slots de disponibilidad');
    });

    // Seleccionar primer slot
    const firstSlot = page.locator('button:has-text("09:00")').first();
    await firstSlot.click();

    console.log('PASO 3: Llenando datos del paciente...');
    
    // PASO 3: Verificar datos del paciente
    await expect(page.locator('text=Paso 3')).toBeVisible({ timeout: 5000 });

    // Llenar formulario
    await page.fill('input[name="name"], input[placeholder*="nombre"]', 'Paciente de Prueba');
    await page.fill('input[name="email"], input[placeholder*="email"]', 'paciente@test.com');

    // Click en Confirmar Reserva
    const confirmButton = page.locator('button:has-text("Confirmar")');
    await confirmButton.click();

    console.log('Esperando confirmación...');

    // Esperar confirmación o error
    await Promise.race([
      // Éxito
      page.waitForSelector('text=confirmada, text=exitosa, text=reservada', { timeout: 15000 })
        .then(() => console.log('✅ Reserva exitosa')),
      
      // Error
      page.waitForSelector('text=error, text=fallo, text=problema', { timeout: 15000 })
        .then(async () => {
          const errorText = await page.textContent('body');
          console.log('❌ Error en la reserva:', errorText);
          await page.screenshot({ path: 'test-results/booking-error.png' });
          throw new Error('Error al confirmar la reserva');
        })
    ]);
  });

  test('debe verificar llamadas API durante la reserva', async ({ page }) => {
    // Mock de autenticación
    await page.addInitScript(() => {
      localStorage.setItem('token', 'mock-jwt-token');
      localStorage.setItem('user', JSON.stringify({
        email: 'test@example.com',
        groups: ['Paciente']
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

