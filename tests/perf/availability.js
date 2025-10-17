import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend } from 'k6/metrics';
import { handleSummary } from './k6-summary.js';

const API_BASE_URL = __ENV.API_BASE_URL || 'http://localhost:8787';
const AUTH_TOKEN = __ENV.AUTH_TOKEN || '';

export const options = {
  scenarios: {
    ramp_availability: {
      executor: 'ramping-arrival-rate',
      startRate: 0,
      timeUnit: '1s',
      preAllocatedVUs: 10,
      maxVUs: 100,
      stages: [
        { target: 25, duration: '5m' },
        { target: 50, duration: '10m' },
        { target: 0, duration: '2m' }
      ]
    }
  },
  thresholds: {
    http_req_failed: ['rate<0.02'],
    checks: ['rate>0.95']
  }
};

const availabilityTrend = new Trend('availability_duration', true);

export default function () {
  const url = `${API_BASE_URL}/booking/availability`;
  const payload = JSON.stringify({
    site_id: 'site-001',
    professional_id: 'prof-001',
    treatment_id: 't-001',
    start_date: '2025-10-10',
    end_date: '2025-10-17'
  });
  const headers = { 'Content-Type': 'application/json' };
  if (AUTH_TOKEN) headers['Authorization'] = `Bearer ${AUTH_TOKEN}`;

  const res = http.post(url, payload, { headers });
  availabilityTrend.add(res.timings.duration);

  check(res, {
    'status esperado (200 o 401)': (r) => r.status === 200 || r.status === 401 || r.status === 403,
    'contenido json o error': (r) =>
      (r.status === 200 && (r.headers['Content-Type'] || '').includes('application/json')) ||
      (r.status >= 400)
  });

  sleep(0.5);
}

export { handleSummary };


