import { test, expect } from '@playwright/test';
import { API_BASE_URL } from '../src/config.js';

test.describe('Contratos de API (sin credenciales)', () => {
  test('GET /health devuelve 200 y estructura esperada', async ({ request }) => {
    const res = await request.get(`${API_BASE_URL}/health`);
    expect(res.status()).toBe(200);

    const json = await res.json();
    expect(json).toHaveProperty('service');
    expect(json).toHaveProperty('status');

    const headers = res.headers();
    expect(headers['content-type'] || '').toContain('application/json');
    // Cabecera opcional (permitir ausencia en entornos previos)
    if (headers['x-content-type-options']) {
      expect(headers['x-content-type-options']).toBe('nosniff');
    }
  });

  test('GET /treatments requiere autenticación', async ({ request }) => {
    const res = await request.get(`${API_BASE_URL}/treatments?tenant_id=tenant-demo-001`);
    expect([401, 403]).toContain(res.status());
  });

  test('GET /professionals requiere autenticación', async ({ request }) => {
    const res = await request.get(`${API_BASE_URL}/professionals?tenant_id=tenant-demo-001`);
    expect([401, 403]).toContain(res.status());
  });

  test('POST /booking/availability requiere autenticación', async ({ request }) => {
    const payload = {
      site_id: 'site-001',
      professional_id: 'prof-001',
      treatment_id: 't-001',
      start_date: '2025-10-10',
      end_date: '2025-10-17'
    };
    const res = await request.post(`${API_BASE_URL}/booking/availability`, {
      data: payload
    });
    expect([401, 403]).toContain(res.status());
  });
});


