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

## To-dos (final)

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
