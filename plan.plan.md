<!-- f0f38f13-e846-4c6f-99b6-57a63bab6066 7b9080b4-e4e1-4010-a72f-ef34646fcf10 -->
# Plan de Entrega MVP Estable — SaaS de Citas Odontológicas (sin pagos)

## Objetivo y alcance

- **Objetivo**: Publicar un MVP estable multi-tenant para gestión de citas odontológicas, listo para dev/qas/prd.
- **Alcance**: Sin pagos; autenticación Cognito + JWT; motor de reservas (crear, listar, reprogramar, cancelar); catálogos (tenants, profesionales, tratamientos); recordatorios por email; panel admin; portal paciente; calendario.

## Entregables

- **Backend (Rust + Lambda)**: Endpoints estables con validación, multitenancy enforcement y trazabilidad.
- **Frontend (SvelteKit)**: Flujos completos (auth, booking 3 pasos, my-appointments, admin, calendar) con manejo de errores y roles.
- **Infra (Terraform)**: Stacks dev/qas/prd con API Gateway (JWT), DynamoDB, Cognito, S3/CloudFront, SES, WAF, CloudWatch/X-Ray.
- **Calidad/Observabilidad**: Dashboards, alarmas críticas, logs estructurados, E2E (Playwright) estables.
- **Operación**: Datos semilla, RUNBOOK, checklist de despliegue y soporte.

## Fases y actividades

### F1. Consolidación técnica backend (Rust) (2–3 días)

- Revisar y completar `bookings` (crear/listar/PUT reprogramar/DELETE cancelar), idempotencia básica y validación.
- Forzar multitenancy: derivar `tenant_id` del JWT y validar contra payload en todas las rutas protegidas.
- Normalizar respuestas/errores en `backend/shared-lib/src/{error.rs,response.rs}`; añadir correlación (request id) y `tracing`.
- Afinar `availability` (slots, bordes horarios, colisiones) y consistencia con la duración de tratamientos/buffers.
- Notificaciones: cablear `send-notification` (SES) y `schedule-reminder` (EventBridge) con plantillas existentes.

### F2. UX/roles frontend (SvelteKit) (2 días)

- Parametrizar auth/URLs por ambiente en `frontend/src/config.js`; evitar hardcodes en `auth.svelte.ts` y callback.
- Tipar `ApiClient` (`frontend/src/lib/api.svelte.ts`) y manejo unificado de errores; toasts/estados de carga.
- Pulir wizard de reserva, `my-appointments`, `admin` (ABM catálogos) y `calendar` (lectura/escritura según rol).
- Gateo por rol: Owner/Admin/Odontólogo/Recepción/Paciente en navegación y acciones.

### F3. Infraestructura y CI/CD (1–2 días)

- Finalizar `terraform/environments/{dev,qas,prd}`: CORS explícito, throttling por ambiente, PITR DynamoDB (qas/prd).
- Configurar SES (identidad verificada, sandbox/allowlist), WAF básico y CloudFront para el frontend.
- Ajustar workflows de GitHub Actions (plan/apply dev/qas automáticos, prd manual con aprobaciones).

### F4. Observabilidad y calidad (1 día)

- CloudWatch dashboards (latencia, 4xx/5xx, throttles), alarmas (5xx altas, errores Lambda, cuota SES).
- Activar X-Ray/tracing en Lambdas críticas y propagar contextos.
- Estabilizar E2E Playwright (auth, booking, admin) y tests unitarios esenciales en Rust.

### F5. Datos, onboarding y UAT (1–2 días)

- Actualizar `scripts/seed-database.sh` y `backend/seed-data.json` para un tenant demo completo.
- Guía de onboarding (crear tenant, asignar roles en Cognito, configurar dominios/URLs de callback).
- UAT con checklist; corrección de bugs de severidad alta.

## Cambios clave por componente (archivos principales)

- Backend
- `backend/functions/bookings/src/main.rs`: validar entrada, idempotencia, cancelación/reprogramación consistente, trazas.
- `backend/functions/availability/src/main.rs`: lógica de slots y validaciones de bordes.
- `backend/shared-lib/src/{dynamodb.rs,error.rs,response.rs,tracing.rs}`: helpers tipados, mapping de errores, respuesta uniforme.
- `backend/functions/send-notification/src/main.rs` + `templates/*.html`: integración SES, variables de plantilla.
- `backend/functions/schedule-reminder/src/main.rs`: payload y programación EventBridge.
- Frontend
- `frontend/src/lib/auth.svelte.ts` y `frontend/src/routes/auth/callback/+page.svelte`: parametrizar dominios/redirects por ambiente.
- `frontend/src/lib/api.svelte.ts`: tipados de respuestas y `return await res.json()` consistente; manejo de 401.
- `frontend/src/routes/{booking, my-appointments, admin, calendar}/+page.svelte`: validaciones y UX.
- `frontend/src/config.js`: endpoints y Cognito por ambiente.
- Infra y CI/CD
- `terraform/environments/*/{main.tf,api-routes.tf,terraform.tfvars}`: CORS, rutas, throttling, PITR.
- `terraform/modules/{ses,waf,api-gateway,cognito,lambda}`: wiring mínimo necesario.
- `.github/workflows/*`: gates, entornos, approvals prd.

## Criterios de aceptación

- Autenticación/roles funcionales; rutas protegidas rechazan accesos sin JWT o de otro tenant.
- Flujo de reserva completo (crear, ver, reprogramar, cancelar) sin overbooking, con recordatorio por email en dev.
- E2E Playwright verdes en dev y qas; errores Lambda < 1% en 24h de pruebas.
- Dashboards/alertas activos; despliegue reproducible con Terraform en dev/qas/prd.
- Documentación operativa y de despliegue actualizada.

## Timeline tentativo (7–10 días hábiles)

- Días 1–3: F1 Backend
- Días 4–5: F2 Frontend
- Días 6–7: F3 Infra + F4 Observabilidad
- Días 8–9: F5 UAT y fixes
- Día 10: Release PRD (ventana controlada)

## Riesgos y mitigaciones

- SES en sandbox: verificar identidad y direcciones de prueba; plan de salida de sandbox.
- Variabilidad de CORS/redirects: parametrización estricta por ambiente.
- Concurrencia en reservas: uso de TransactWrite y claves compuestas; pruebas de carga ligeras.

## Notas de implementación

- Seguir tipado explícito en servicios, evitar `any` en `ApiClient`.
- Respetar huso horario `America/Guayaquil` en scripts/generación de fechas.
- Mantener indentación de 2 espacios y convenciones ya presentes.

### To-dos

- [x] Consolidar `bookings` (validación, idempotencia, cancelación/reprogramación)
- [x] Afinar lógica de `availability` y validaciones de slots
- [x] Unificar errores/respuestas/tracing en shared-lib
- [x] Configurar SES y plantillas para `send-notification`
- [x] Cablear `schedule-reminder` con EventBridge y probar
- [x] Parametrizar dominios/redirects de auth por ambiente
- [x] Tipar ApiClient y manejo unificado de errores
- [x] Pulir wizard de reserva y my-appointments
- [x] Pulir admin (ABM) y calendar con gateo por rol
- [x] Finalizar Terraform dev/qas/prd (CORS, throttling, PITR)
- [x] Ajustar workflows con gates y aprobaciones prd
- [x] Dashboards/alarms CloudWatch y X-Ray tracing
- [x] Actualizar semillas y guía de onboarding
- [x] Estabilizar E2E Playwright y unit tests Rust
- [x] Actualizar RUNBOOK, DEPLOYMENT y API
