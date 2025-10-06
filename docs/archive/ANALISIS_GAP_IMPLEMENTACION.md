# Análisis de GAP — Estado Actual vs Especificación Completa
**Fecha**: 2025-09-29  
**Objetivo**: Identificar features faltantes para implementación al 100%

---

## Estado Actual del Sistema

### ✅ Completado (15% del sistema total)

#### Infraestructura
- [x] Monorepo con workspaces (frontend, infra, backend)
- [x] CDK bootstrap con qualifier custom
- [x] DevStack: API Gateway HTTP + 2 Lambdas (health, availability mock)
- [x] FrontendStack: S3 + CloudFront + Route53 + ACM (en creación, 70%)
- [x] CI/CD workflows (GitHub Actions: backend-ci, frontend-ci)
- [x] Naming convention (`tk-nq` prefix)

#### Backend
- [x] Runtime Rust 1.89 con lambda_http 0.13, AL2023, ARM64
- [x] Shared library (error handling, response builders, tracing)
- [x] Tests unitarios (4 tests pasando)
- [x] Linting (rustfmt, clippy)
- [x] X-Ray tracing habilitado
- [x] Logs con retención 7 días
- [x] Validación de inputs (validator crate)

#### Frontend
- [x] SvelteKit 2.28 + Svelte 5.38 (Runes)
- [x] TypeScript configurado (strict mode)
- [x] Linting (ESLint + Prettier)
- [x] UI moderna básica (1 página con verificación de API)
- [x] Build estático funcional
- [x] Preview local operativo

---

## ❌ Faltante (85% restante) — Priorizado por épica

### E1. Infra & Pipeline (60% completado)
**Falta**:
- [ ] ObservabilityStack: CloudWatch Dashboard, alarmas SNS, métricas custom
- [ ] Multi-stage (dev/stage/prod) con CDK Pipelines
- [ ] Feature flags (AWS AppConfig)
- [ ] CDK assertions tests

### E2. Identidad (0% completado) — **CRÍTICO**
**Falta TODO**:
- [ ] AuthStack con Cognito User Pool
- [ ] Hosted UI de Cognito (registro/login)
- [ ] Grupos/roles (Owner, Admin, Odontólogo, Recepción, Paciente)
- [ ] JWT authorizer en API Gateway
- [ ] MFA configurable
- [ ] Password policy
- [ ] Account recovery flows

### E3. Tenancy (0% completado) — **CRÍTICO**
**Falta TODO**:
- [ ] DataStack con DynamoDB single-table
- [ ] Endpoints: POST /tenants, GET /tenants/:id, PATCH /tenants/:id
- [ ] Lambda: tenant CRUD
- [ ] Modelo de datos: TENANT entity (PK, SK, branding, config)
- [ ] Gestión de sedes (multi-location)
- [ ] Zonas horarias por sede
- [ ] Políticas de cancelación por tenant

### E4. Catálogo & Recursos (0% completado) — **CRÍTICO**
**Falta TODO**:
- [ ] Endpoints: /treatments, /professionals, /resources
- [ ] Lambdas: catalog CRUD
- [ ] Modelo de datos: TRATAMIENTO, PROFESIONAL, RECURSO (sillón, RX, asistente)
- [ ] Duración + buffers por tratamiento
- [ ] Calendarios por sede/profesional/recurso
- [ ] Reglas de solapamiento

### E5. Motor de Reservas (5% completado) — **CRÍTICO**
**Completado**:
- [x] POST /booking/availability (mock de slots)

**Falta**:
- [ ] Disponibilidad REAL consultando DynamoDB (slots, bloques, solapamientos)
- [ ] POST /booking/reservations (reserva atómica con TransactWriteItems)
- [ ] PATCH /booking/reservations/:id (reprogramación con validación)
- [ ] DELETE /booking/reservations/:id (cancelación según política)
- [ ] Modelo: AGENDA_SLOT, CITA entities
- [ ] ConditionExpressions para evitar overbooking
- [ ] Lista de espera
- [ ] Idempotency keys

### E6. Portal Paciente (PWA) (5% completado)
**Completado**:
- [x] Página inicial con verificación de API

**Falta**:
- [ ] Booking wizard (3 pasos: servicio → fecha/hora → confirmación)
- [ ] Autenticación (login/registro con Cognito)
- [ ] Mis citas (ver, reprogramar, cancelar)
- [ ] Perfil de paciente
- [ ] Pre-anamnesis/consentimientos
- [ ] Subida de adjuntos (S3 presigned URLs)
- [ ] PWA manifest
- [ ] Service worker (offline, push notifications)
- [ ] Recordatorios in-app

### E7. Back-office Agenda (0% completado)
**Falta TODO**:
- [ ] Vista agenda: día/semana/mes
- [ ] Filtros por sede/profesional/recurso
- [ ] Drag & drop de citas
- [ ] Bloqueos administrativos
- [ ] UI de recepción

### E8. Comunicaciones (0% completado)
**Falta TODO**:
- [ ] NotificationsStack: EventBridge Scheduler + SES + Pinpoint + SQS
- [ ] Programación de recordatorios T-24h/T-2h
- [ ] Plantillas SES (multi-idioma)
- [ ] Integración Pinpoint (SMS/WhatsApp)
- [ ] Políticas de envío (quiet hours, reintentos)
- [ ] Dominio verificado en SES (Easy DKIM)

### E9. Centro de Configuración (0% completado)
**Falta TODO**:
- [ ] UI de configuración por categorías (10 categorías)
- [ ] Sistema de borradores
- [ ] Versionado de configuración
- [ ] Publicación programada
- [ ] Rollback a versión anterior
- [ ] Simulador de impacto en agenda
- [ ] Validación JSON Schema
- [ ] Importación/Exportación de config
- [ ] Auditoría de cambios

### E10. IAM en UI (0% completado)
**Falta TODO**:
- [ ] Verified Permissions (Cedar) stack
- [ ] UI: gestión de usuarios
- [ ] UI: roles y políticas
- [ ] Editor visual de matriz de permisos
- [ ] Editor Cedar (con linting)
- [ ] Simulador de decisiones de acceso
- [ ] Invitaciones de usuarios
- [ ] Permisos temporales (JIT)
- [ ] Recertificación

### E11. Observabilidad & Seguridad (30% completado)
**Completado**:
- [x] X-Ray tracing
- [x] CloudWatch Logs con retención
- [x] CORS específico (whitelist)

**Falta**:
- [ ] WAF v2 (rate limiting, AWS Managed Rules)
- [ ] CloudWatch Dashboard
- [ ] Alarmas SNS (error rate, latency)
- [ ] Métricas custom (EMF)
- [ ] OpenSearch para logs centralizados (opcional)

### E12. Pagos (0% completado) — Opcional
**Falta TODO**:
- [ ] Integración Stripe
- [ ] Payment intents
- [ ] Webhooks
- [ ] Recibos

### E13. Analítica & Reportes (0% completado)
**Falta TODO**:
- [ ] Dashboard operacional
- [ ] KPIs: no-show, ocupación, lead time
- [ ] Exportaciones CSV
- [ ] Data lake (opcional)

---

## Resumen de Cobertura

| Épica | Completado | Faltante | % |
|-------|-----------|----------|---|
| E1. Infra & Pipeline | 60% | 40% | 🟢 |
| E2. Identidad (Cognito) | 0% | 100% | 🔴 |
| E3. Tenancy | 0% | 100% | 🔴 |
| E4. Catálogo & Recursos | 0% | 100% | 🔴 |
| E5. Motor Reservas | 5% | 95% | 🔴 |
| E6. Portal Paciente | 5% | 95% | 🔴 |
| E7. Back-office Agenda | 0% | 100% | 🔴 |
| E8. Comunicaciones | 0% | 100% | 🔴 |
| E9. Centro Config | 0% | 100% | 🔴 |
| E10. IAM UI | 0% | 100% | 🔴 |
| E11. Obs & Seguridad | 30% | 70% | 🟡 |
| E12. Pagos | 0% | 100% | ⚪ |
| E13. Analítica | 0% | 100% | 🟡 |
| **TOTAL** | **~15%** | **~85%** | 🔴 |

---

## Plan de Implementación al 100%

### Fase 1: Fundamentos Críticos (Sprint 0.5 + 1 + 2 del backlog) — 3-4 semanas

**Prioridad absoluta** (sin esto, el sistema no funciona):

1. **AuthStack (Cognito)** — 2 días
   - User Pool, App Client, Hosted UI
   - Grupos: Owner, Admin, Odontólogo, Recepción, Paciente
   - JWT authorizer en API Gateway
   - Login/registro en frontend

2. **DataStack (DynamoDB single-table)** — 2 días
   - Table con PK/SK, GSI1, GSI2
   - TTL, PITR, encryption
   - Seed data script

3. **Tenancy CRUD** — 3 días
   - Backend: POST/GET/PATCH /tenants
   - Frontend: UI de gestión de tenant/sedes
   - Modelo: TENANT, SEDE entities

4. **Catálogo CRUD** — 3 días
   - Backend: /treatments, /professionals, /resources
   - Frontend: UI de administración
   - Modelo: TRATAMIENTO, PROFESIONAL, RECURSO

5. **WAF + Alarmas** — 1 día
   - WAF v2 con rate limiting
   - SNS topic + alarmas básicas
   - Dashboard CloudWatch

### Fase 2: Motor de Reservas Real (Sprint 2-3) — 2-3 semanas

6. **Disponibilidad real** — 4 días
   - Consulta DynamoDB (slots, bloqueos, solapamientos)
   - Rules engine (buffers, preparación)
   - Cache selectiva

7. **Reserva atómica** — 3 días
   - TransactWriteItems + ConditionExpressions
   - Idempotency keys
   - Gestión de conflictos (409 + alternativas)

8. **Reprogramación/Cancelación** — 2 días
   - Validación de políticas por tenant
   - Lista de espera automática
   - Notificaciones

### Fase 3: Portales de Usuario (Sprint 3-4) — 3-4 semanas

9. **Portal Paciente (Booking Wizard)** — 5 días
   - Step 1: selección de servicio/sede/profesional
   - Step 2: calendario con slots disponibles
   - Step 3: confirmación + datos paciente
   - Integración con autenticación

10. **Portal Paciente (Gestión)** — 3 días
   - Mis citas (historial, próximas)
   - Reprogramar/cancelar
   - Perfil y preferencias

11. **Back-office Agenda** — 5 días
   - Vistas día/semana/mes (FullCalendar o similar)
   - Drag & drop
   - Bloqueos
   - Filtros avanzados

### Fase 4: Comunicaciones (Sprint 4) — 2 semanas

12. **NotificationsStack** — 3 días
   - EventBridge Scheduler
   - SES con dominio verificado + Easy DKIM
   - Pinpoint setup
   - SQS FIFO

13. **Recordatorios** — 4 días
   - Programación T-24h/T-2h
   - Plantillas multi-idioma
   - Quiet hours, reintentos
   - Webhooks de estado

### Fase 5: Configuración Avanzada (Sprint 4-5) — 2-3 semanas

14. **Centro de Configuración** — 7 días
   - UI por categorías (10 categorías)
   - Sistema de borradores + publicación
   - Versionado + rollback
   - Simulador de impacto
   - Validación JSON Schema

15. **IAM en UI** — 5 días
   - Verified Permissions stack
   - UI de usuarios/roles/políticas
   - Editor Cedar con linting
   - Simulador de acceso
   - Invitaciones

### Fase 6: Analítica y Pulido (Sprint 5-6) — 2 semanas

16. **Dashboard Operacional** — 3 días
   - KPIs: no-show, ocupación, lead time
   - Gráficos (Chart.js o Recharts)
   - Exportaciones CSV

17. **PWA Completo** — 2 días
   - Manifest
   - Service worker
   - Offline mode
   - Push notifications

18. **Pagos (opcional)** — 3 días
   - Stripe integration
   - Payment intents
   - Webhooks

---

## Estimación Total

| Fase | Duración | Complejidad | Dependencias |
|------|----------|-------------|--------------|
| **Fase 1**: Fundaciones | 3-4 semanas | Alta | Ninguna (puede empezar ya) |
| **Fase 2**: Motor Reservas | 2-3 semanas | Alta | Fase 1 (Auth, Data, Catálogo) |
| **Fase 3**: Portales | 3-4 semanas | Media | Fase 1, 2 |
| **Fase 4**: Comunicaciones | 2 semanas | Media | Fase 1, 2 |
| **Fase 5**: Config + IAM UI | 2-3 semanas | Alta | Fase 1 |
| **Fase 6**: Analítica + PWA | 2 semanas | Baja | Fase 2, 3 |
| **TOTAL** | **14-20 semanas** | - | - |

---

## Enfoque de Implementación Acelerada (100% en esta sesión)

Dado el alcance masivo, voy a implementar una **versión funcional end-to-end** que cubra:

### Bloque A: Auth + Data (base para todo) — 1 hora
1. AuthStack: Cognito User Pool + JWT authorizer
2. DataStack: DynamoDB single-table con seed data
3. Actualizar DevStack para usar el authorizer
4. Frontend: login/registro básico

### Bloque B: Catálogo + Reservas básicas — 1 hora
5. Backend: CRUD de tenants, treatments, professionals, resources
6. Backend: Disponibilidad real + reserva atómica
7. DynamoDB: modelo completo con GSIs
8. Frontend: booking wizard simplificado (3 pasos)

### Bloque C: Comunicaciones + Config — 45 min
9. NotificationsStack: EventBridge + SES
10. Recordatorios básicos (T-24h)
11. Centro de Config: borrador + publicación simple

### Bloque D: UI/UX + PWA — 30 min
12. Portal paciente: mis citas
13. Back-office: agenda día (tabla simple)
14. PWA: manifest + service worker
15. Dashboard básico

### Bloque E: IAM + Observabilidad — 30 min
16. Verified Permissions básico
17. WAF + alarmas
18. CloudWatch Dashboard

**Total estimado**: ~3-4 horas de implementación enfocada

---

## Priorización Recomendada

Si el tiempo es limitado, implementar en este orden (valor decreciente):

1. **Auth + Data** (sin esto, nada funciona)
2. **Catálogo** (datos maestros esenciales)
3. **Motor de Reservas real** (core del negocio)
4. **Portal Paciente básico** (UX crítica)
5. **WAF + Seguridad** (antes de producción)
6. **Comunicaciones** (valor diferencial)
7. **Back-office** (operaciones diarias)
8. **Config + IAM UI** (autonomía operativa)
9. **Analítica** (optimización)
10. **Pagos** (monetización)

---

## Decisión de Alcance

**Opción 1: MVP Funcional (40% del total)** — ~4 horas
- Auth, Data, Catálogo, Reservas básicas, Portal paciente, WAF

**Opción 2: MMP Completo (100%)** — 14-20 semanas (equipo de 4-5 devs)
- Todas las épicas según backlog

**Opción 3: Demostración End-to-End (20%)** — ~2 horas
- Auth mock, reserva simplificada, UI pulida

¿Qué alcance prefieres que implemente ahora?
