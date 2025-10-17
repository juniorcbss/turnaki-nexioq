import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Rate } from 'k6/metrics';
import { handleSummary } from './k6-summary.js';

const API_BASE_URL = __ENV.API_BASE_URL || 'http://localhost:8787';
const AUTH_TOKEN = __ENV.AUTH_TOKEN || '';

export const options = {
  scenarios: {
    throttle: {
      executor: 'ramping-arrival-rate',
      startRate: 0,
      timeUnit: '1s',
      preAllocatedVUs: 20,
      maxVUs: 200,
      stages: [
        { target: 100, duration: '5m' },
        { target: 200, duration: '5m' },
        { target: 0, duration: '2m' }
      ]
    },
    latency_injection: {
      executor: 'constant-arrival-rate',
      rate: 20,
      timeUnit: '1s',
      duration: '10m',
      preAllocatedVUs: 20,
      maxVUs: 50
    }
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    checks: ['rate>0.9']
  }
};

const availabilityDuration = new Trend('resilience_availability_duration', true);
const had429 = new Rate('rate_429');

export default function () {
  const headers = { 'Content-Type': 'application/json' };
  if (AUTH_TOKEN) headers['Authorization'] = `Bearer ${AUTH_TOKEN}`;

  const url = `${API_BASE_URL}/booking/availability`;
  const payload = JSON.stringify({
    site_id: 'site-001',
    professional_id: 'prof-001',
    treatment_id: 't-001',
    start_date: '2025-10-10',
    end_date: '2025-10-17'
  });

  const res = http.post(url, payload, { headers, timeout: '60s' });
  availabilityDuration.add(res.timings.duration);
  had429.add(res.status === 429);

  check(res, {
    'respuesta válida o error controlado': (r) => [200, 401, 403, 429, 500].includes(r.status)
  });

  // Emular variación de latencia del cliente (no del servidor)
  sleep(Math.random() * 0.2);
}

export { handleSummary };


