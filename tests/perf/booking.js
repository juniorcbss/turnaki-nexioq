import http from 'k6/http';
import { check, sleep } from 'k6';
import { handleSummary } from './k6-summary.js';

const API_BASE_URL = __ENV.API_BASE_URL || 'http://localhost:8787';
const AUTH_TOKEN = __ENV.AUTH_TOKEN || '';

export const options = {
  vus: 20,
  duration: '10m',
  thresholds: {
    http_req_failed: ['rate<0.02'],
    checks: ['rate>0.95']
  }
};

export default function () {
  if (!AUTH_TOKEN) {
    // Sin token, no intentamos reservar para evitar ruido
    return;
  }

  const headers = { 'Content-Type': 'application/json', Authorization: `Bearer ${AUTH_TOKEN}` };

  // Paso 1: disponibilidad (idealmente con datos reales del seed)
  const availPayload = JSON.stringify({
    site_id: 'site-001',
    professional_id: 'prof-001',
    treatment_id: 't-001',
    start_date: '2025-10-10',
    end_date: '2025-10-17'
  });
  const avail = http.post(`${API_BASE_URL}/booking/availability`, availPayload, { headers });

  // Paso 2: crear booking simulado si hay slots
  let ok = true;
  try {
    const json = avail.json();
    if (avail.status === 200 && json && json.slots && json.slots.length > 0) {
      const slot = json.slots[0];
      const bookPayload = JSON.stringify({
        tenant_id: 'tenant-demo-001',
        patient_id: 'patient-perf',
        professional_id: slot.professional_id || 'prof-001',
        treatment_id: 't-001',
        slot_id: slot.slot_id || 'slot-1',
        date_time: `${slot.date || '2025-10-10'}T09:00:00Z`,
        patient_name: 'k6 Perf',
        patient_email: 'k6@example.com'
      });
      const booking = http.post(`${API_BASE_URL}/bookings`, bookPayload, { headers });
      ok = booking.status === 201 || booking.status === 409 || booking.status === 422;
    }
  } catch (_e) {
    ok = false;
  }

  check(avail, { 'availability ok/401/403': (r) => r.status === 200 || r.status === 401 || r.status === 403 });
  check({ ok }, { 'booking intento aceptable': (v) => v.ok });

  sleep(0.5);
}

export { handleSummary };


