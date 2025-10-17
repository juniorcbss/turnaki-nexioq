import { test } from '@playwright/test';

test('DEBUG: Ver exactamente qué pasa al cargar /booking', async ({ page }) => {
  console.log('\n🔍 ===== INICIANDO DEBUG =====\n');
  
  // Configurar mock de auth ANTES de ir a la página
  await page.addInitScript(() => {
    // Usar la clave correcta: tk_nq_token
    const mockToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJuYW1lIjoiVGVzdCBVc2VyIiwiY29nbml0bzpncm91cHMiOlsiUGFjaWVudGUiXX0.test';
    localStorage.setItem('tk_nq_token', mockToken);
    console.log('✅ Token mock configurado');
  });

  // Capturar TODOS los logs
  page.on('console', msg => {
    const type = msg.type();
    const text = msg.text();
    const emoji = type === 'error' ? '🔴' : type === 'warning' ? '🟡' : '🔵';
    console.log(`${emoji} [${type}] ${text}`);
  });

  // Capturar requests
  page.on('request', req => {
    if (req.url().includes('execute-api') || req.url().includes('treatments') || req.url().includes('booking')) {
      console.log(`📤 REQUEST: ${req.method()} ${req.url()}`);
      const headers = req.headers();
      if (headers.authorization) {
        console.log(`   Authorization: ${headers.authorization.substring(0, 50)}...`);
      }
    }
  });

  // Capturar responses
  page.on('response', async res => {
    if (res.url().includes('execute-api') || res.url().includes('treatments') || res.url().includes('booking')) {
      const status = res.status();
      console.log(`📥 RESPONSE: ${status} ${res.url()}`);
      try {
        const body = await res.text();
        console.log(`   Body (primeros 200 chars): ${body.substring(0, 200)}`);
      } catch (e) {
        console.log(`   Body: [no se pudo leer]`);
      }
    }
  });

  console.log('\n📍 Navegando a /booking...\n');
  await page.goto(`${process.env.E2E_BASE_URL || 'http://localhost:5173'}/booking`, { waitUntil: 'networkidle' });

  // Esperar un poco
  await page.waitForTimeout(3000);

  // Ver qué hay en localStorage
  const storageState = await page.evaluate(() => {
    return {
      token: localStorage.getItem('tk_nq_token'),
      user: localStorage.getItem('user'),
      allKeys: Object.keys(localStorage)
    };
  });

  console.log('\n📦 ESTADO DE LOCALSTORAGE:');
  console.log('   Token:', storageState.token ? `${storageState.token.substring(0, 50)}...` : 'NO EXISTE');
  console.log('   User:', storageState.user);
  console.log('   Todas las claves:', storageState.allKeys);

  // Ver qué hay en la página
  const bodyText = await page.textContent('body');
  const hasError = bodyText?.includes('error') || bodyText?.includes('Error');
  const hasTreatments = bodyText?.includes('Limpieza') || bodyText?.includes('Dental');
  const hasLoading = bodyText?.includes('Cargando') || bodyText?.includes('loading');

  console.log('\n📄 CONTENIDO DE LA PÁGINA:');
  console.log('   Tiene "error":', hasError);
  console.log('   Tiene "Limpieza/Dental":', hasTreatments);
  console.log('   Tiene "Cargando":', hasLoading);
  console.log('   Texto (primeros 500 chars):', bodyText?.substring(0, 500));

  // Screenshot
  await page.screenshot({ 
    path: 'test-results/debug-booking.png',
    fullPage: true 
  });

  console.log('\n📸 Screenshot guardado: test-results/debug-booking.png');
  console.log('\n🔍 ===== FIN DEBUG =====\n');
});
