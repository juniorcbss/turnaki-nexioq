# Pruebas de Rendimiento (k6)

Variables:
- `API_BASE_URL`: base del API Gateway (ej: https://xxxx.execute-api.us-east-1.amazonaws.com)
- `AUTH_TOKEN` (opcional): JWT Cognito para escenarios autenticados

Comandos ejemplo:
```bash
API_BASE_URL=https://api.example.com k6 run tests/perf/availability.js
API_BASE_URL=https://api.example.com AUTH_TOKEN=eyJ... k6 run tests/perf/booking.js
```


