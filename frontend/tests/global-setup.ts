import { FullConfig } from '@playwright/test';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

async function globalSetup(_config: FullConfig) {
  if (!process.env.SEED_E2E) return;
  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);
  const repoRoot = path.resolve(__dirname, '..', '..');
  const scriptPath = path.join(repoRoot, 'scripts', 'seed-tests.sh');
  const result = spawnSync('bash', [scriptPath], {
    stdio: 'inherit',
    env: {
      ...process.env,
      TZ: 'America/Guayaquil',
      NOW_ISO: process.env.NOW_ISO || '2025-10-01T09:00:00Z'
    }
  });
  if (result.status !== 0) {
    throw new Error('Fallo al ejecutar semillas E2E');
  }
}

export default globalSetup;


