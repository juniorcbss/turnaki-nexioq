import { test, expect } from '@playwright/test';

// Test EXHAUSTIVO del flujo de reserva
test.use({
  headless: false,
  viewport: { width: 1280, height: 900 },
  slowMo: 500,
});

test.describe('🔬 Prueba EXHAUSTIVA de Booking', () => {

  test('Flujo completo con autenticación mock', async ({ page }) => {
    console.log('\n╔════════════════════════════════════════════════════════════╗');
    console.log('║  🔬 PRUEBA EXHAUSTIVA DE RESERVA - PASO POR PASO         ║');
    console.log('╚════════════════════════════════════════════════════════════╝\n');

    // Setup: Mock de autenticación
    await page.addInitScript(() => {
      const mockToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJuYW1lIjoiVGVzdCBVc2VyIiwiY29nbml0bzpncm91cHMiOlsiUGFjaWVudGUiXX0.test';
      localStorage.setItem('tk_nq_token', mockToken);
      console.log('✅ Token mock configurado');
    });

    // Interceptar llamadas API y registrar TODO
    const apiCalls: any[] = [];
    
    page.on('console', msg => {
      if (msg.type() === 'error') {
        console.log(`🔴 CONSOLE ERROR: ${msg.text()}`);
      }
    });

    page.on('request', req => {
      if (req.url().includes('execute-api') || req.url().includes('localhost:5173')) {
        const call = {
          method: req.method(),
          url: req.url(),
          timestamp: new Date().toISOString()
        };
        apiCalls.push(call);
        if (req.url().includes('execute-api')) {
          console.log(`\n📤 API REQUEST: ${req.method()} ${req.url().split('amazonaws.com')[1]}`);
        }
      }
    });

    page.on('response', async res => {
      if (res.url().includes('execute-api')) {
        console.log(`📥 API RESPONSE: ${res.status()} ${res.url().split('amazonaws.com')[1]}`);
        try {
          const body = await res.text();
          console.log(`   Body: ${body.substring(0, 150)}${body.length > 150 ? '...' : ''}`);
        } catch (e) {}
      }
    });

    // ═══════════════════════════════════════════════════════════
    // PASO 1: Cargar página /booking
    // ═══════════════════════════════════════════════════════════
    console.log('\n━━━ PASO 1: Cargando /booking ━━━');
    
    await page.goto('http://localhost:5173/booking');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);

    // Screenshot inicial
    await page.screenshot({ path: 'test-results/exhaustive-01-inicial.png', fullPage: true });
    console.log('✅ Página cargada');
    console.log('📸 Screenshot: exhaustive-01-inicial.png');

    // Verificar estado inicial
    const step1Visible = await page.locator('.step.active:has-text("1. Servicio")').isVisible();
    console.log(`   Step 1 activo: ${step1Visible ? '✅' : '❌'}`);
    expect(step1Visible).toBeTruthy();

    // ═══════════════════════════════════════════════════════════
    // PASO 2: Verificar carga de tratamientos
    // ═══════════════════════════════════════════════════════════
    console.log('\n━━━ PASO 2: Verificando tratamientos ━━━');
    
    await page.waitForTimeout(1000);
    
    const treatments = await page.locator('.treatment-card').count();
    console.log(`   Tratamientos encontrados: ${treatments}`);
    
    if (treatments === 0) {
      const bodyText = await page.textContent('body');
      console.log(`   ⚠️  No se encontraron tratamientos`);
      console.log(`   Contenido de la página: ${bodyText?.substring(0, 300)}`);
    }

    await page.screenshot({ path: 'test-results/exhaustive-02-tratamientos.png', fullPage: true });
    console.log('📸 Screenshot: exhaustive-02-tratamientos.png');

    // Esperar a que haya al menos un tratamiento
    await expect(page.locator('.treatment-card').first()).toBeVisible({ timeout: 5000 });

    // ═══════════════════════════════════════════════════════════
    // PASO 3: Seleccionar primer tratamiento
    // ═══════════════════════════════════════════════════════════
    console.log('\n━━━ PASO 3: Seleccionando tratamiento ━━━');
    
    const firstTreatment = page.locator('.treatment-card').first();
    const treatmentName = await firstTreatment.locator('h3').textContent();
    console.log(`   Seleccionando: ${treatmentName}`);
    
    await firstTreatment.click();
    await page.waitForTimeout(2000);

    await page.screenshot({ path: 'test-results/exhaustive-03-tratamiento-seleccionado.png', fullPage: true });
    console.log('✅ Tratamiento seleccionado');
    console.log('📸 Screenshot: exhaustive-03-tratamiento-seleccionado.png');

    // Verificar que avanzó al paso 2
    const step2Visible = await page.locator('.step.active:has-text("2. Fecha/Hora")').isVisible();
    console.log(`   Step 2 activo: ${step2Visible ? '✅' : '❌'}`);
    expect(step2Visible).toBeTruthy();

    // ═══════════════════════════════════════════════════════════
    // PASO 4: Verificar campo de fecha
    // ═══════════════════════════════════════════════════════════
    console.log('\n━━━ PASO 4: Verificando campo de fecha ━━━');
    
    const dateInput = page.locator('input[type="date"]');
    const dateInputVisible = await dateInput.isVisible();
    console.log(`   Input de fecha visible: ${dateInputVisible ? '✅' : '❌'}`);
    
    const dateValue = await dateInput.inputValue();
    console.log(`   Fecha actual: ${dateValue || '(vacío)'}`);

    // ═══════════════════════════════════════════════════════════
    // PASO 5: Verificar botones "Volver" (BUG REPORTADO)
    // ═══════════════════════════════════════════════════════════
    console.log('\n━━━ PASO 5: Verificando botones "Volver" ━━━');
    
    const volverButtons = await page.locator('button:has-text("Volver")').count();
    console.log(`   Botones "Volver" encontrados: ${volverButtons}`);
    
    if (volverButtons > 1) {
      console.log(`   🐛 BUG CONFIRMADO: ${volverButtons} botones "Volver" (debería ser 1)`);
    }

    await page.screenshot({ path: 'test-results/exhaustive-04-bug-volver.png', fullPage: true });
    console.log('📸 Screenshot: exhaustive-04-bug-volver.png');

    // ═══════════════════════════════════════════════════════════
    // PASO 6: Verificar slots de horario
    // ═══════════════════════════════════════════════════════════
    console.log('\n━━━ PASO 6: Verificando slots de horario ━━━');
    
    await page.waitForTimeout(2000);
    
    const slotsCount = await page.locator('.slot-btn').count();
    console.log(`   Slots de horario encontrados: ${slotsCount}`);
    
    if (slotsCount === 0) {
      console.log(`   🐛 BUG CONFIRMADO: No se muestran slots de horario`);
      
      // Verificar si hay mensaje de error
      const bodyText = await page.textContent('body');
      const hasError = bodyText?.includes('error') || bodyText?.includes('disponible');
      console.log(`   Hay mensaje de error: ${hasError ? 'SÍ' : 'NO'}`);
      console.log(`   Contenido relevante: ${bodyText?.substring(bodyText.indexOf('Selecciona'), bodyText.indexOf('Selecciona') + 200)}`);
      
      // Verificar si está cargando
      const isLoading = bodyText?.includes('Cargando');
      console.log(`   Está cargando: ${isLoading ? 'SÍ' : 'NO'}`);
    }

    await page.screenshot({ path: 'test-results/exhaustive-05-slots.png', fullPage: true });
    console.log('📸 Screenshot: exhaustive-05-slots.png');

    // ═══════════════════════════════════════════════════════════
    // PASO 7: Intentar cambiar la fecha manualmente
    // ═══════════════════════════════════════════════════════════
    console.log('\n━━━ PASO 7: Cambiando fecha manualmente ━━━');
    
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStr = tomorrow.toISOString().split('T')[0];
    
    console.log(`   Estableciendo fecha: ${tomorrowStr}`);
    await dateInput.fill(tomorrowStr);
    await dateInput.blur(); // Trigger onchange
    
    await page.waitForTimeout(3000);
    
    const slotsAfterChange = await page.locator('.slot-btn').count();
    console.log(`   Slots después de cambiar fecha: ${slotsAfterChange}`);

    await page.screenshot({ path: 'test-results/exhaustive-06-fecha-cambiada.png', fullPage: true });
    console.log('📸 Screenshot: exhaustive-06-fecha-cambiada.png');

    // ═══════════════════════════════════════════════════════════
    // PASO 8: Probar botón "Volver"
    // ═══════════════════════════════════════════════════════════
    console.log('\n━━━ PASO 8: Probando botón Volver ━━━');
    
    const volverBtn = page.locator('button:has-text("Volver")').first();
    await volverBtn.click();
    await page.waitForTimeout(1000);
    
    const backToStep1 = await page.locator('.step.active:has-text("1. Servicio")').isVisible();
    console.log(`   Volvió al paso 1: ${backToStep1 ? '✅' : '❌'}`);

    await page.screenshot({ path: 'test-results/exhaustive-07-volver.png', fullPage: true });
    console.log('📸 Screenshot: exhaustive-07-volver.png');

    // ═══════════════════════════════════════════════════════════
    // RESUMEN FINAL
    // ═══════════════════════════════════════════════════════════
    console.log('\n╔════════════════════════════════════════════════════════════╗');
    console.log('║  📊 RESUMEN DE LA PRUEBA EXHAUSTIVA                       ║');
    console.log('╚════════════════════════════════════════════════════════════╝\n');
    
    console.log(`✓ Tratamientos cargados: ${treatments > 0 ? 'SÍ' : 'NO'}`);
    console.log(`✓ Navegación al paso 2: ${step2Visible ? 'SÍ' : 'NO'}`);
    console.log(`✓ Campo de fecha visible: ${dateInputVisible ? 'SÍ' : 'NO'}`);
    console.log(`🐛 Botones "Volver" duplicados: ${volverButtons > 1 ? 'SÍ' : 'NO'}`);
    console.log(`🐛 Slots NO se muestran: ${slotsCount === 0 ? 'SÍ' : 'NO'}`);
    console.log(`✓ Botón volver funciona: ${backToStep1 ? 'SÍ' : 'NO'}`);
    console.log(`\n📊 Total llamadas API: ${apiCalls.filter(c => c.url.includes('execute-api')).length}`);
    console.log(`📸 Total screenshots: 7`);
    
    console.log('\n🔍 Archivos generados:');
    console.log('   • test-results/exhaustive-01-inicial.png');
    console.log('   • test-results/exhaustive-02-tratamientos.png');
    console.log('   • test-results/exhaustive-03-tratamiento-seleccionado.png');
    console.log('   • test-results/exhaustive-04-bug-volver.png');
    console.log('   • test-results/exhaustive-05-slots.png');
    console.log('   • test-results/exhaustive-06-fecha-cambiada.png');
    console.log('   • test-results/exhaustive-07-volver.png\n');

    // Mantener navegador abierto
    await page.waitForTimeout(5000);
  });
});

