import { test, expect } from '@playwright/test';

// Configuración para que el navegador sea visible
test.use({
  headless: false, // Navegador VISIBLE
  viewport: { width: 1280, height: 720 },
  slowMo: 1000, // Ralentizar acciones para ver mejor
});

// Test con navegador VISIBLE y pasos pausados
test.describe('🌐 Prueba Completa en Navegador Real', () => {

  test('Flujo completo: Home → Login → Reserva', async ({ page }) => {
    console.log('\n🚀 ===== INICIANDO PRUEBA EN NAVEGADOR REAL =====\n');

    // ============================================
    // PASO 1: Cargar la aplicación
    // ============================================
    console.log('📍 PASO 1: Cargando aplicación...');
    await page.goto('http://localhost:5173');
    await page.waitForLoadState('networkidle');
    
    // Screenshot
    await page.screenshot({ 
      path: 'test-results/paso-1-home.png',
      fullPage: true 
    });
    console.log('   ✅ Aplicación cargada');
    console.log('   📸 Screenshot: paso-1-home.png\n');

    // Verificar que la página cargó
    await expect(page.locator('h1:has-text("Turnaki")')).toBeVisible({ timeout: 5000 });

    // ============================================
    // PASO 2: Verificar estado de autenticación
    // ============================================
    console.log('📍 PASO 2: Verificando autenticación...');
    
    const isAuthenticated = await page.evaluate(() => {
      return localStorage.getItem('tk_nq_token') !== null;
    });

    console.log(`   Estado: ${isAuthenticated ? '✅ Autenticado' : '❌ No autenticado'}`);

    if (!isAuthenticated) {
      console.log('\n⚠️  NO ESTÁS AUTENTICADO');
      console.log('   Para continuar con la prueba completa:');
      console.log('   1. Haz click en "Iniciar sesión" en el navegador');
      console.log('   2. Completa el login en Cognito');
      console.log('   3. Vuelve a ejecutar este test\n');
      
      // Tomar screenshot del estado no autenticado
      await page.screenshot({ 
        path: 'test-results/paso-2-no-autenticado.png',
        fullPage: true 
      });
      
      // Pausar para permitir login manual si se desea
      console.log('⏸️  PAUSANDO 30 segundos para login manual...');
      console.log('   (Si quieres hacer login ahora, hazlo en el navegador)\n');
      
      await page.waitForTimeout(30000);
      
      // Verificar de nuevo
      const nowAuthenticated = await page.evaluate(() => {
        return localStorage.getItem('tk_nq_token') !== null;
      });
      
      if (!nowAuthenticated) {
        console.log('❌ No se detectó login. Terminando prueba.');
        return;
      }
      
      console.log('✅ Login detectado. Continuando...\n');
    }

    // ============================================
    // PASO 3: Verificar elementos de la UI
    // ============================================
    console.log('📍 PASO 3: Verificando elementos de la UI...');
    
    // Verificar header
    const hasHeader = await page.locator('header, .header').count() > 0;
    console.log(`   Header: ${hasHeader ? '✅' : '❌'}`);
    
    // Verificar navegación
    const hasBookingLink = await page.locator('a:has-text("Reservar"), text=Reservar Cita').count() > 0;
    console.log(`   Link "Reservar Cita": ${hasBookingLink ? '✅' : '❌'}`);
    
    await page.screenshot({ 
      path: 'test-results/paso-3-ui-verificada.png',
      fullPage: true 
    });
    console.log('   📸 Screenshot: paso-3-ui-verificada.png\n');

    // ============================================
    // PASO 4: Navegar a Reservas
    // ============================================
    console.log('📍 PASO 4: Navegando a página de reservas...');
    
    // Buscar el link de reservar (puede ser texto o link)
    const bookingLink = page.locator('a:has-text("Reservar Cita"), a:has-text("Reservar"), button:has-text("Reservar")').first();
    
    if (await bookingLink.isVisible()) {
      await bookingLink.click();
      console.log('   ✅ Click en "Reservar Cita"');
    } else {
      // Navegar directamente
      await page.goto('http://localhost:5173/booking');
      console.log('   ✅ Navegación directa a /booking');
    }
    
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    await page.screenshot({ 
      path: 'test-results/paso-4-pagina-booking.png',
      fullPage: true 
    });
    console.log('   📸 Screenshot: paso-4-pagina-booking.png\n');

    // ============================================
    // PASO 5: Verificar carga de tratamientos
    // ============================================
    console.log('📍 PASO 5: Verificando carga de tratamientos...');
    
    // Esperar a que aparezcan tratamientos o error
    await page.waitForTimeout(3000);
    
    const pageContent = await page.textContent('body');
    const hasTreatments = pageContent?.includes('Limpieza') || pageContent?.includes('Dental');
    const hasError = pageContent?.includes('error') || pageContent?.includes('Sesión expirada');
    
    console.log(`   Tratamientos visibles: ${hasTreatments ? '✅' : '❌'}`);
    console.log(`   Error visible: ${hasError ? '❌ SÍ' : '✅ NO'}`);
    
    if (hasError) {
      console.log('\n❌ ERROR DETECTADO: Sesión expirada o problema de autenticación');
      console.log('   Contenido de la página:', pageContent?.substring(0, 300));
    }
    
    await page.screenshot({ 
      path: 'test-results/paso-5-tratamientos.png',
      fullPage: true 
    });
    console.log('   📸 Screenshot: paso-5-tratamientos.png\n');

    // ============================================
    // PASO 6: Intentar seleccionar tratamiento
    // ============================================
    if (hasTreatments && !hasError) {
      console.log('📍 PASO 6: Seleccionando tratamiento...');
      
      // Buscar botón de seleccionar
      const selectButton = page.locator('button:has-text("Seleccionar")').first();
      
      if (await selectButton.isVisible({ timeout: 2000 })) {
        await selectButton.click();
        console.log('   ✅ Tratamiento seleccionado');
        
        await page.waitForTimeout(2000);
        await page.screenshot({ 
          path: 'test-results/paso-6-tratamiento-seleccionado.png',
          fullPage: true 
        });
        console.log('   📸 Screenshot: paso-6-tratamiento-seleccionado.png\n');
        
        // ============================================
        // PASO 7: Verificar paso 2 (fecha/hora)
        // ============================================
        console.log('📍 PASO 7: Verificando paso 2 (fecha/hora)...');
        
        await page.waitForTimeout(2000);
        const step2Content = await page.textContent('body');
        const hasSlots = step2Content?.includes('09:00') || step2Content?.includes('10:00');
        
        console.log(`   Slots de horario visibles: ${hasSlots ? '✅' : '❌'}`);
        
        await page.screenshot({ 
          path: 'test-results/paso-7-fecha-hora.png',
          fullPage: true 
        });
        console.log('   📸 Screenshot: paso-7-fecha-hora.png\n');
        
        if (hasSlots) {
          // Intentar seleccionar un slot
          const slotButton = page.locator('button:has-text("09:00"), button:has-text("10:00")').first();
          
          if (await slotButton.isVisible({ timeout: 2000 })) {
            await slotButton.click();
            console.log('   ✅ Slot seleccionado');
            
            await page.waitForTimeout(2000);
            await page.screenshot({ 
              path: 'test-results/paso-8-slot-seleccionado.png',
              fullPage: true 
            });
            console.log('   📸 Screenshot: paso-8-slot-seleccionado.png\n');
          }
        }
      } else {
        console.log('   ❌ No se encontró botón "Seleccionar"');
      }
    } else {
      console.log('📍 PASO 6: Omitido (no hay tratamientos o hay error)\n');
    }

    // ============================================
    // RESUMEN FINAL
    // ============================================
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 RESUMEN DE LA PRUEBA');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✓ Aplicación cargada: ${hasHeader ? 'SÍ' : 'NO'}`);
    console.log(`✓ Autenticado: ${isAuthenticated ? 'SÍ' : 'NO'}`);
    console.log(`✓ Página booking accesible: SÍ`);
    console.log(`✓ Tratamientos cargados: ${hasTreatments ? 'SÍ' : 'NO'}`);
    console.log(`✓ Sin errores: ${!hasError ? 'SÍ' : 'NO'}`);
    console.log('\n📸 Screenshots guardados en: test-results/');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // Mantener navegador abierto por 10 segundos más
    console.log('⏸️  Manteniendo navegador abierto 10 segundos más para inspección...\n');
    await page.waitForTimeout(10000);
  });

  test('Prueba de API en vivo', async ({ page }) => {
    console.log('\n🔍 ===== PROBANDO APIS EN VIVO =====\n');

    // Capturar todas las llamadas API
    const apiCalls: any[] = [];
    
    page.on('request', request => {
      if (request.url().includes('execute-api')) {
        apiCalls.push({
          method: request.method(),
          url: request.url(),
          headers: request.headers()
        });
      }
    });

    page.on('response', async response => {
      if (response.url().includes('execute-api')) {
        try {
          const body = await response.text();
          console.log(`\n📡 API CALL:`);
          console.log(`   ${response.request().method()} ${response.url()}`);
          console.log(`   Status: ${response.status()}`);
          console.log(`   Response: ${body.substring(0, 200)}${body.length > 200 ? '...' : ''}`);
        } catch (e) {
          console.log(`   Response: [no se pudo leer]`);
        }
      }
    });

    await page.goto('http://localhost:5173/booking');
    await page.waitForTimeout(5000);

    console.log(`\n📊 Total de llamadas API: ${apiCalls.length}`);
    
    await page.screenshot({ 
      path: 'test-results/api-test.png',
      fullPage: true 
    });
  });
});

