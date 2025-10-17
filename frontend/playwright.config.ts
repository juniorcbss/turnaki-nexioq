import { defineConfig, devices } from '@playwright/test';

// Permitir correr E2E contra entorno remoto (CloudFront) sin levantar servidor local
const E2E_BASE_URL = process.env.E2E_BASE_URL || 'http://localhost:5173';
const USE_REMOTE = !!process.env.E2E_BASE_URL;

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  
  use: {
    baseURL: E2E_BASE_URL,
    locale: 'es-EC',
    timezoneId: 'America/Guayaquil',
    launchOptions: {
      args: [
        '--disable-blink-features=AutomationControlled',
        '--disable-dev-shm-usage',
        '--no-sandbox'
      ]
    },
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  globalSetup: process.env.SEED_E2E ? './tests/global-setup.ts' : undefined,

  webServer: USE_REMOTE ? undefined : {
    command: 'npm run start:dev -- --port 5173',
    port: 5173,
    reuseExistingServer: !process.env.CI,
  },
});
