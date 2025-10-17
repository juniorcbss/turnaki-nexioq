# 💻 Guía de Desarrollo

---

## Setup Inicial

### Pre-requisitos

```bash
# Herramientas requeridas
node >= 20
rust >= 1.75
cargo-lambda
aws-cli >= 2.x
terraform >= 1.9
```

### Instalación

```bash
# Clonar repositorio
git clone <repo-url>
cd turnaki-nexioq

# Instalar dependencias frontend
cd frontend
npm install

# Instalar cargo-lambda
cargo install cargo-lambda
```

---

## Desarrollo Local

### Frontend

```bash
cd frontend
npm run dev
```

Abre: http://localhost:5173

### Backend (Rust Lambdas)

```bash
# Compilar
cd backend
cargo build

# Tests
cargo test --workspace

# Watch mode (hot reload)
cargo watch -x test
```

### Invocar Lambda Localmente

```bash
cd backend
cargo lambda watch

# En otra terminal
cargo lambda invoke --data-file test-event.json health
```

---

## Estructura del Proyecto

```
turnaki-nexioq/
├── backend/              # Rust Lambdas
│   ├── functions/        # 8 Lambdas
│   └── shared-lib/       # Código compartido
├── frontend/             # SvelteKit
│   ├── src/
│   │   ├── lib/          # Stores, utilities
│   │   └── routes/       # Páginas
│   └── e2e/              # Tests Playwright
├── terraform/            # Infraestructura
│   ├── modules/          # Módulos reutilizables
│   └── environments/     # dev/qas/prd
├── docs/                 # Documentación
└── scripts/              # Scripts operativos
```

---

## Comandos Comunes

### Build

```bash
# Backend (todas las lambdas)
cd backend
cargo lambda build --arm64 --release

# Frontend
cd frontend
npm run build
```

### Testing

```bash
# Backend
cargo test --workspace

# Frontend unit tests
npm -w frontend run test

# E2E tests
npm -w frontend run test:e2e
```

### Linting

```bash
# Backend
cd backend
cargo fmt
cargo clippy

# Frontend
cd frontend
npm run lint
```

---

## Variables de Entorno

### Frontend (.env.local)

```bash
VITE_API_BASE=https://x292iexx8a.execute-api.us-east-1.amazonaws.com
VITE_COGNITO_DOMAIN=tk-nq-auth.auth.us-east-1.amazoncognito.com
VITE_COGNITO_CLIENT_ID=pcffkjudd2vho10lr0l8luona
VITE_COGNITO_REDIRECT_URI=http://localhost:5173
```

### Backend (en Terraform)

```hcl
environment {
  variables = {
    TABLE_NAME = aws_dynamodb_table.main.name
    LOG_LEVEL  = "info"
    RUST_LOG   = "info"
  }
}
```

---

## Debugging

### Frontend

```typescript
// Consola del navegador
console.log($app.user);
console.log(localStorage.getItem('tk_nq_token'));
```

### Backend

```rust
// Usar tracing
tracing::info!("Processing booking: {:?}", booking);
tracing::error!("Error: {:?}", error);

// Logs en CloudWatch
aws logs tail /aws/lambda/tk-nq-dev-health --follow
```

---

## Contribuir

### Workflow

1. Crear rama feature
2. Hacer cambios
3. Tests pasan
4. Commit con mensaje descriptivo
5. Push y crear PR

### Commit Messages

```
feat: agregar búsqueda de profesionales
fix: corregir validación de email
docs: actualizar README con nuevos endpoints
test: agregar tests para bookings
refactor: extraer lógica de validación
```

---

**Última actualización**: Octubre 2025

## E2E y Semillas

- Ejecutar E2E con servidor dev y semillas deterministas:

```bash
cd frontend
SEED_E2E=1 npm run test:e2e
```

- Semillas deterministas manuales (opcional):

```bash
TZ=America/Guayaquil NOW_ISO=2025-10-01T09:00:00Z ./scripts/seed-tests.sh
```

- Roles de ejemplo para pruebas:
  - Admin: `localStorage.user = { email: 'admin@test.com', groups: ['Admin'], tenant_id: 'tenant-demo-001' }`
  - Paciente: `localStorage.user = { email: 'user@test.com', groups: ['Paciente'], tenant_id: 'tenant-demo-001' }`

- Guards de rol:
  - `admin`: requiere `Admin` u `Owner` en `authStore.user.groups`.
  - `calendar`: requiere uno de `Admin | Owner | Recepción | Odontólogo`.

- Configuración Playwright relevante:
  - `webServer`: `npm run start:dev` en `http://localhost:5173`
  - `use.timezoneId`: `America/Guayaquil`
  - `use.locale`: `es-EC`
  - Flags anti‑detección en `use.launchOptions.args`
