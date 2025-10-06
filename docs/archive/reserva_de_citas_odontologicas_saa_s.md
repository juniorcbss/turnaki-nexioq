# Plataforma SaaS de Reserva de Citas Odontológicas
**Especificación funcional y técnica completa (2025) — Multi‑tenant, 100% configurable, seguridad de nivel empresarial**

---

## Resumen ejecutivo
Aplicación SaaS orientada a clínicas odontológicas y profesionales independientes para gestionar reservas, agendas, comunicaciones y reportes. La solución es **multi‑tenant**, **serverless** sobre AWS, con **backend en Rust** y **frontend en SvelteKit**, totalmente configurable desde la interfaz, incluyendo **IAM en UI** (usuarios, roles, políticas y ámbitos) y un **centro de configuración** con versionado, publicación programada y *rollback*.

---

## Índice
- [Plataforma SaaS de Reserva de Citas Odontológicas](#plataforma-saas-de-reserva-de-citas-odontológicas)
  - [Resumen ejecutivo](#resumen-ejecutivo)
  - [Índice](#índice)
  - [Prompt maestro (copiar/pegar)](#prompt-maestro-copiarpegar)
  - [Fundamentos y versiones (verificados en producción)](#fundamentos-y-versiones-verificados-en-producción)
  - [Especificación funcional](#especificación-funcional)
    - [3.1 Gestión de inquilinos (multi‑tenant)](#31-gestión-de-inquilinos-multitenant)
    - [3.2 Identidad, acceso y permisos](#32-identidad-acceso-y-permisos)
    - [3.3 Catálogo clínico y configuración](#33-catálogo-clínico-y-configuración)
    - [3.4 Motor de reservas (Booking Engine)](#34-motor-de-reservas-booking-engine)
    - [3.5 Portal del paciente (PWA)](#35-portal-del-paciente-pwa)
    - [3.6 Recordatorios y comunicaciones](#36-recordatorios-y-comunicaciones)
    - [3.7 Agenda operativa (Back‑office)](#37-agenda-operativa-backoffice)
    - [3.8 Facturación/abonos (opcional)](#38-facturaciónabonos-opcional)
    - [3.9 Reportería y analítica](#39-reportería-y-analítica)
    - [3.10 Cumplimiento, privacidad y auditoría](#310-cumplimiento-privacidad-y-auditoría)
    - [3.11 Centro de Configuración (UI 100% configurable)](#311-centro-de-configuración-ui-100-configurable)
    - [3.12 Módulo IAM en la interfaz (RBAC + ABAC)](#312-módulo-iam-en-la-interfaz-rbac--abac)
  - [Diseño técnico (alto nivel)](#diseño-técnico-alto-nivel)
    - [4.1 Backend (Rust en Lambda)](#41-backend-rust-en-lambda)
    - [4.2 Frontend (SvelteKit 2 + Svelte 5)](#42-frontend-sveltekit-2--svelte-5)
    - [4.3 Seguridad](#43-seguridad)
    - [4.4 Infra como código (CDK v2)](#44-infra-como-código-cdk-v2)
  - [API (endpoints clave — ejemplos)](#api-endpoints-clave--ejemplos)
  - [Modelo de datos single‑table (ejemplos)](#modelo-de-datos-singletable-ejemplos)
  - [Flujos operativos](#flujos-operativos)
  - [Operación, calidad y costes](#operación-calidad-y-costes)
  - [Beneficios clave](#beneficios-clave)
  - [Próximos pasos sugeridos](#próximos-pasos-sugeridos)
    - [✅ Completado (MVP inicial desplegado)](#-completado-mvp-inicial-desplegado)
    - [🔄 En curso](#-en-curso)
    - [📋 Sprint 1 (siguiente, 2 semanas) — Fundaciones de calidad](#-sprint-1-siguiente-2-semanas--fundaciones-de-calidad)
    - [📋 Sprint 2 (2 semanas) — Seguridad y persistencia](#-sprint-2-2-semanas--seguridad-y-persistencia)
    - [📋 Sprint 3+ (MMP) — Features avanzadas](#-sprint-3-mmp--features-avanzadas)
  - [Referencias técnicas](#referencias-técnicas)
    - [Verificadas en implementación MVP (2025-08-12)](#verificadas-en-implementación-mvp-2025-08-12)
    - [Herramientas de desarrollo](#herramientas-de-desarrollo)
    - [Repositorio del proyecto](#repositorio-del-proyecto)

---

## Prompt maestro (copiar/pegar)
> **Objetivo:** Genera una **aplicación SaaS multi‑tenant de reserva de citas odontológicas**, 100% configurable, con UI **moderna/futurista/minimalista**.  \
> **Arquitectura:** Serverless en AWS. **Backend en Rust** sobre AWS Lambda + API Gateway (HTTP APIs) + Amazon Cognito (User Pools, OAuth2/OIDC, Hosted UI). Persistencia en Amazon DynamoDB (single‑table, GSIs, TTL, TransactWrite/ConditionExpressions para evitar doble reserva). Orquestación con Amazon EventBridge Scheduler para recordatorios; colas SQS (FIFO donde aplique) para tareas asíncronas; notificaciones vía Amazon SES (autenticación de dominio con Easy DKIM) y Amazon Pinpoint (incluyendo WhatsApp vía *Custom Channel*). **Frontend en SvelteKit 2.x / Svelte 5 (Runes)**, empaquetado con Vite y desplegado estático en **S3 + CloudFront** (OAC, HTTPS, *security headers*). **IaC con AWS CDK v2** (stacks modulares + Pipelines).  \
> **Calidad/seguridad/operabilidad:** seguir AWS Well‑Architected (Serverless), trazabilidad (X‑Ray/ADOT), métricas CloudWatch/EMF, logs estructurados; JWT authorizer en API Gateway; WAF; *rate limiting* y CORS; mínimo privilegio en IAM; auditoría y **Amazon Verified Permissions (Cedar)** para ABAC/RBAC fino.  \
> **UX/UI:** SvelteKit con diseño futurista (tipografía generosa, micro‑interacciones), tema claro/oscuro, PWA (offline/*precaching*), i18n (es/en).  \
> **Entrega:** monorepo con workspaces, CI/CD (GitHub Actions) hacia CDK Pipelines (dev/stage/prod). Semillas de datos y *tests* (unitarios, contract y e2e).  \
> **Genera:**  
> 1) Árbol de proyecto y carpetas.  
> 2) Infra CDK (stacks: Auth, API, Data, Notifications, Frontend, Observability, Pipeline).  
> 3) Lambdas en Rust (handlers Axum/`lambda_http`) con ejemplos de endpoints críticos.  
> 4) Modelo single‑table (PK/SK, GSIs, entidades).  
> 5) Frontend SvelteKit (rutas, layouts, *stores/runes*, formularios con validación).  
> 6) Flujos clave (booking/recordatorios/pagos opcionales).  
> 7) Pruebas y scripts de carga.  
> 8) Guías **RUNBOOK** y **README** de despliegue.  \
> **Restricciones:** calidad de código alta, tipado estricto, idempotencia, *feature flags* (AppConfig), tiempos por tratamiento, gestión de recursos (sillones) y multi‑sede, sin *overbooking*.  \
> **Salida esperada:** código + documentación + diagramas ASCII + comandos de despliegue.

---

## Fundamentos y versiones (verificados en producción)
- **Rust estable**: 1.89.0 (agosto 2025), toolchain `aarch64-apple-darwin`
- **Rust en Lambda**: 
  - `lambda_http` **0.13+** (runtime v2, mejora 30% performance vs 0.11)
  - `lambda_runtime` 0.13+ con soporte nativo para AL2023
  - **Cargo Lambda 1.8.6+** para cross-compile ARM64 (`--arm64 --release --output-format zip`)
  - Runtime: `provided.al2023` (reemplaza `provided.al2` deprecado)
- **SvelteKit 2.28+** con **Svelte 5.38+ (Runes: `$state`, `$derived`, `$effect`)** y **Vite 7.1+**
- **Cognito + API Gateway (HTTP API) con JWT authorizer** (OAuth2/OIDC, Hosted UI)
- **DynamoDB**: *single‑table design*, **ConditionExpressions** y **TransactWriteItems** para garantías atómicas (evitar doble reserva)
- **EventBridge Scheduler**: programaciones puntuales y recurrentes con integración directa a Lambda
- **SES**: autenticación de dominios con **Easy DKIM** (plantillas y remitentes verificados). **Pinpoint**: SMS/WhatsApp
- **Front** en **S3 + CloudFront** con **OAI** (OriginAccessIdentity), **ACM** (Certificate Manager con DNS validation), HTTPS, *security headers* (CSP, HSTS, X-Frame-Options)
- **CDK v2.150+**: constructos L2/L3, **CDK Pipelines**, context/feature flags
- **Naming convention**: prefijo `tk-nq` para todos los recursos AWS (Lambdas, API, buckets, roles)
- **Observabilidad**: X-Ray tracing, CloudWatch Logs (retención 1 semana), CloudWatch Insights, EMF para métricas custom
- **Testing**: Vitest (frontend), cargo-test + cargo-nextest (backend), Playwright (e2e)
- **Linting**: ESLint + Prettier (frontend), rustfmt + clippy (backend)
- **CI/CD**: GitHub Actions con OIDC (sin secrets), cache de deps (Swatinem/rust-cache, actions/cache)

> **Lecciones aprendidas (MVP desplegado)**:
> - OAI deprecado en favor de OAC (Origin Access Control), pero compatible hasta 2026
> - Certificate Manager con DNS validation requiere 5-10 min (automático con Route53)
> - cargo-lambda con `--arm64` reduce cold-start ~40% vs x86_64
> - Vite 7 requiere ajustes en config de SvelteKit (adapter-static con `fallback`)
> - Bootstrap CDK con qualifier custom (`turnaki`) evita conflictos multi-cuenta
> - CORS wildcard (`*`) bloqueado en producción; whitelist obligatoria

---

## Especificación funcional

### 3.1 Gestión de inquilinos (multi‑tenant)
- Alta de clínica (nombre, identificaciones fiscales, sedes, horarios macro, políticas de cancelación, zonas horarias).  
- Planes/cuotas (agenda por profesional, límites de comunicaciones, almacenamiento, retención).  
- Branding por tenant (logo, paleta, dominio personalizado para portal de pacientes).

### 3.2 Identidad, acceso y permisos
- **Cognito User Pools** con MFA configurable, Hosted UI, OAuth2/OIDC; grupos/roles por clínica (Owner, Admin, Odontólogo, Recepción).  
- **JWT authorizer** en API Gateway con *scopes* por recurso.  
- **Verified Permissions (Cedar)** para ABAC (p. ej., *odontólogo edita solo sus citas*) y auditoría de decisiones.

### 3.3 Catálogo clínico y configuración
- Tratamientos (duración base, buffers, recursos: sillón, RX, asistente).  
- Calendarios por sede/profesional/recurso con **bloques** y reglas anti‑solapamiento.

### 3.4 Motor de reservas (Booking Engine)
- Disponibilidad en tiempo real por sede/profesional/recurso; *rules engine* para buffers y preparación.  
- **Confirmación atómica** con `TransactWriteItems` + `ConditionExpressions` para garantizar bloque libre.  
- Reprogramaciones/cancelaciones según política por tenant; lista de espera; **sin *overbooking***.

### 3.5 Portal del paciente (PWA)
- Autogestión: registro, historial, reserva/reprogramación/cancelación, pre‑anamnesis/consentimientos, subida de adjuntos.  
- Recordatorios *in‑app* y *push* cuando el navegador lo permita.

### 3.6 Recordatorios y comunicaciones
- Programación T‑24h y T‑2h con **EventBridge Scheduler** (únicos o recurrentes).  
- Envío por **SES** (plantillas, remitentes verificados) y **Pinpoint** (SMS/WhatsApp vía *Custom Channel*).  
- Políticas por tenant: idioma, ventanas de envío, reintentos, *quiet hours*.

### 3.7 Agenda operativa (Back‑office)
- Vistas día/semana/mes; filtros por sede/profesional/recurso.  
- Bloqueos administrativos (mantenimiento, formación).  
- *Drag & drop* con validación en cliente y confirmación del servidor.

### 3.8 Facturación/abonos (opcional)
- Integración con pasarela (Stripe u otra) para adelantos; recibos y reportes básicos.  
- Activación mediante *feature flag* (AppConfig).

### 3.9 Reportería y analítica
- KPIs: *no‑show*, ocupación por sillón/profesional, *lead time*, fuentes de reserva.  
- Exportaciones CSV; eventos opcionales a *data lake*.

### 3.10 Cumplimiento, privacidad y auditoría
- Controles de seguridad (Cognito/WAF), *audit trail* de acciones sensibles, políticas de retención.  
- Avisos legales e información de privacidad por tenant.  
- Recomendación de validación regulatoria local.

### 3.11 Centro de Configuración (UI 100% configurable)
**Objetivo:** administración integral de parámetros sin intervención técnica, con seguridad, versionado, validación y publicación controlada.

**Capas y herencia**  
- **Sistema (global)** → valores por defecto seguros.  
- **Tenant** → sobreescribe global.  
- **Sede** → sobreescribe tenant (horarios/localización/recursos).  
- **Usuario/rol** → preferencias (idioma, zona horaria, accesibilidad).  
Resolución: `sede > tenant > sistema` con *fallback* y auditoría de la fuente efectiva.

**UX del Centro de Configuración**  
- Navegación por categorías, búsqueda global y *breadcrumbs*.  
- Modos **Básico** y **Avanzado** (editor JSON con validación/autocompletado).  
- Previsualización en vivo (tema, logos, plantillas) y **simulador de disponibilidad** antes de publicar.  
- Borrador vs **Publicado** con barra de cambios pendientes y *diff* visual.

**Categorías**  
1) Identidad visual (logo, paleta, modo claro/oscuro, alto contraste, favicon, dominio).  
2) Localización (zona horaria por sede, formatos de fecha/hora, i18n y textos).  
3) Políticas de reserva (anticipación mínima/máxima, cancelación, *no‑show*, recargos, buffers por servicio).  
4) Agenda y recursos (horarios por sede/profesional, excepciones/feriados, asignación de recursos, reglas de solapamiento).  
5) Notificaciones (canales, plantillas multi‑idioma, *quiet hours*, reintentos, remitentes).  
6) Privacidad y retención (tiempos por entidad, ofuscación, exportación).  
7) Pagos (opcional) (pasarela, moneda, anticipo por servicio, reembolsos).  
8) Integraciones (webhooks, iCal, claves API, *callback URLs*).  
9) Accesibilidad (tamaño de fuente, foco visible, contraste, animaciones reducidas).  
10) *Feature Flags* (activación gradual por tenant/sede/rol; *kill switch*).

**Validación y simulación**  
- Validación en cliente y servidor con **JSON Schema** y reglas cruzadas (p. ej., buffers ≤ duración).  
- **Simulador de agenda**: recalcula disponibilidad con el borrador y muestra impactos (slots añadidos/eliminados por día).

**Versionado, publicación y *rollback***  
- Cada cambio crea una **versión** (autor, fecha, comentario, *diff*).  
- Publicación atómica, programable (p. ej., domingo 22:00).  
- **Rollback** a una versión anterior con un clic.  
- Flujo opcional de **aprobación** (4‑eyes) para categorías sensibles.

**Importación/Exportación**  
- Exportar configuración como JSON firmado; importar con validación y vista de diferencias.  
- Plantillas reutilizables por industria/sucursal.

**Auditoría y alertas**  
- *Audit trail* por campo (quién, qué, antes/después) con búsquedas por usuario y rango.  
- Alertas ante cambios críticos o errores de publicación.

**APIs**  
- `GET /config/:tenantId` (efectiva, cacheable con ETag)  
- `GET /config/:tenantId/draft`  
- `PUT /config/:tenantId/draft` (validación server‑side)  
- `POST /config/:tenantId/publish` (opcional `scheduleAt`)  
- `GET /config/:tenantId/versions` · `POST /config/:tenantId/rollback/:versionId`  
- `POST /config/:tenantId/import` · `GET /config/:tenantId/export`

**Modelo (DynamoDB)**  
- `PK=CONFIG#TENANT#<t>` · `SK=VERSION#<n>` → versión completa.  
- `PK=CONFIG#TENANT#<t>` · `SK=DRAFT` → borrador actual.  
- Índices por `publishedAt` y categoría modificada.

**Eventos**  
- `ConfigChanged` en EventBridge con *payload* del *diff* → *listeners*: invalidación de cachés, recálculo de agendas, invalidación de CloudFront, rotación de plantillas SES/Pinpoint.

**Seguridad**  
- Permisos por categoría (ver/editar/publicar), *break‑glass* controlado y **guardrails** de valores.

### 3.12 Módulo IAM en la interfaz (RBAC + ABAC)
**Objetivo:** administración de acceso desde la UI: usuarios, grupos, roles, políticas, ámbitos (tenant/sede/recurso) y simulación de decisiones. Integra Cognito (identidad) y Verified Permissions (autorización) bajo RBAC+ABAC.

**Componentes**  
- **Usuarios**: alta/invitación, estado (pendiente/activo/bloqueado), MFA, atributos (nombre, email, teléfono, rol primario, sedes).  
- **Grupos/Roles**: plantillas (Owner, Admin, Recepción, Odontólogo, Analista, Finanzas, Invitado) clonables por tenant.  
- **Políticas**: editor visual (matriz recurso×acción×ámbito) y editor avanzado (Cedar) con *linting* y pruebas de políticas.  
- **Ámbitos**: tenant, sede, profesional, recurso; atributos (ABAC) como `tenantId`, `siteId`, `role`, `ownerId`.

**Flujos**  
1) **Invitar usuario** → correo con enlace; al aceptar, se asignan roles y sedes; MFA opcional.  
2) **Permisos temporales (JIT)** → duración/alcance con aprobación.  
3) **Recertificación** periódica → reportes por rol/usuario; revocación masiva.  
4) **Bloqueo y baja** → efecto inmediato en Cognito y Cedar; revocación de sesiones.

**UI/UX**  
- **Matriz de permisos** por recurso (Citas, Agenda, Pacientes, Tratamientos, Configuración, Reportes, IAM) × acciones (read, create, update, delete, export, configure, publish).  
- Filtros por sede; búsqueda por usuario/grupo.  
- **Simulador de acceso**: ingresar `actor`, `acción`, `recurso` y atributos → resultado **ALLOW/DENY** con trazabilidad y *decisionId*.  
- *Drill‑down* desde una denegación hacia la política responsable.

**Modelo de autorización**  
- **RBAC** para permisos comunes + **ABAC** (Cedar) para restricciones por atributos.  
- **Scopes** de JWT para API Gateway (p. ej., `appointments:write`) verificados en el *authorizer*.

**Seguridad**  
- MFA obligatoria para roles sensibles; políticas de contraseña; recuperación de cuenta con flujos seguros.  
- **Mínimo privilegio**, *deny‑by‑default* y separación de deberes.  
- **Break‑glass**: cuenta de emergencia con *vault* y auditoría reforzada.

**APIs**  
- `POST /iam/users/invite` · `PATCH /iam/users/{id}` (activar/bloquear/atributos)  
- `GET /iam/roles` · `POST /iam/roles` (desde plantilla) · `PUT /iam/roles/{id}`  
- `GET /iam/policies` · `POST /iam/policies` (Cedar) · `POST /iam/policies/validate`  
- `POST /iam/simulate` (actor, acción, recurso, atributos)  
- `POST /iam/assignments` (usuario↔rol↔ámbito) · `DELETE /iam/assignments/{id}`

**Modelo (DynamoDB)**  
- **Directorio**: mapeo `cognitoSub → tenantId → roles → sedes → atributos` para consultas rápidas en UI.  
- Historial de cambios y *decision logs* almacenable y consultable.

**Integraciones**  
- **Cognito**: alta/bloqueo de usuarios, grupos y MFA desde la UI.  
- **Verified Permissions**: sincronización, prueba y publicación de políticas con versiones y *rollback*.  
- **API Gateway**: *authorizer* JWT con *scopes*; el backend consulta Verified Permissions por recurso/atributo.

**Operación**  
- Panel de **accesos anómalos** (picos de denegaciones, intentos fallidos, *logins* sospechosos).  
- **Reportes de cumplimiento**: export CSV/PDF (usuarios por rol, permisos efectivos, accesos temporales, eventos críticos).

---

## Diseño técnico (alto nivel)

### 4.1 Backend (Rust en Lambda)
- **Framework HTTP**: `lambda_http` 0.13+ (runtime v2), *cold‑start* <200ms en ARM64 con binarios optimizados
- **Compilación**: **Cargo Lambda 1.8.6+** con `--arm64 --release --output-format zip` para target `aarch64-unknown-linux-gnu`
- **Runtime**: `provided.al2023` (Amazon Linux 2023, soporte hasta 2028+)
- **Arquitectura**: ARM64 (Graviton2) — 20% más eficiente y 20% más económico vs x86_64
- **API Gateway HTTP API** con JWT authorizer (Cognito). Rutas REST consistentes, prefijo `tk-nq-api`
- **Shared library** (`backend/shared-lib/`):
  - Error handling estructurado (`thiserror`, `anyhow`)
  - Response builders con headers de seguridad
  - Validación de inputs (`validator` crate)
  - Tracing JSON estructurado con contexto (request_id, tenant_id)
  - Utilidades de idempotencia (hash de `idempotency-key` headers)
- **DynamoDB (single‑table)**  
  - **Keys**: `PK`, `SK`, `GSI1PK`, `GSI1SK`, `GSI2PK` (tenant isolation)
  - **Billing**: PAY_PER_REQUEST (serverless), encryption AWS_MANAGED, PITR habilitado
  - **Entidades**: TENANT, SEDE, PRO (profesional), RECURSO, PACIENTE, TRATAMIENTO, AGENDA_SLOT, CITA, EVENTO_COMUNICACION, CONFIG_VERSION
  - **Anti‑colisiones**: `TransactWriteItems` + `ConditionExpression attribute_not_exists` sobre `AGENDA_SLOT`
  - **TTL**: tokens temporales, eventos de comunicación antiguos
- **Asíncrono**: SQS **FIFO** cuando se requiera orden por `MessageGroupId` (p. ej., `tenant#sede`), con *exactly‑once* de cola e idempotencia en consumidor
- **Recordatorios**: **EventBridge Scheduler** → Lambda → SES/Pinpoint (reintentos y ventanas flexibles)
- **Observabilidad**: 
  - CloudWatch Logs (JSON, retención 7 días) + EMF (métricas custom)
  - X‑Ray tracing ACTIVE en todas las Lambdas
  - CloudWatch Insights habilitado (LambdaInsightsVersion 1.0.229)
  - Alarmas SNS: error rate >1%, p99 latency >3s
- **Testing**: cargo-test + cargo-nextest (paralelo), coverage con tarpaulin

### 4.2 Frontend (SvelteKit 2 + Svelte 5)
- **Stack**: SvelteKit 2.28+, Svelte 5.38+ con **Runes** (`$state`, `$derived`, `$effect`), Vite 7.1+
- **TypeScript**: strict mode, tipos generados automáticamente por SvelteKit (`npm exec svelte-kit sync`)
- **PWA**: vite-plugin-pwa con manifest, service worker, runtime caching (NetworkFirst para API, CacheFirst para assets)
- **Adapter**: `@sveltejs/adapter-static` con `fallback: 'index.html'` para SPA (client-side routing)
- **Estado global**: Svelte 5 runes stores (`api.svelte.ts`, `auth.svelte.ts`, `config.svelte.ts`)
- **Validación**: zod schemas para formularios, mensajes de error i18n
- **Módulos UI**: 
  - Portal paciente: booking wizard (3 pasos), mis citas, perfil
  - Back-office: agenda (día/semana/mes), bloqueos, drag & drop
  - Admin: gestión de tenant, sedes, profesionales, recursos, tratamientos
  - IAM UI: usuarios, roles, políticas (editor visual + Cedar), simulador de acceso
  - Centro de Configuración: editor por categorías, versionado, simulador, rollback
- **Despliegue**: 
  - Build estático en `frontend/build/` (SSG donde sea posible, CSR donde se requiera interactividad)
  - S3 privado `tk-nq-frontend-<account>-<region>` con encryption, versioning opcional
  - CloudFront con **OAI** (migrar a OAC en Q4 2025), ACM certificate (DNS validation), dominio `turnaki.nexioq.com`
  - Security headers: CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy
  - Error responses: 403/404 → `index.html` (TTL 1min) para SPA routing
- **Testing**: Vitest (unit/integration), Playwright (e2e con fixtures), visual regression (Percy o Chromatic)
- **Linting**: ESLint + @typescript-eslint + eslint-plugin-svelte, Prettier con prettier-plugin-svelte
- **Performance**: code splitting automático, lazy loading de rutas, prefetch en hover, image optimization

### 4.3 Seguridad
- **Cognito User Pools**: MFA opcional/obligatoria, password policy (min 12 chars, uppercase, digits, symbols), account recovery, advanced security features
- **API Gateway**: 
  - **WAF v2** (regional): rate limiting (2000 req/5min por IP), AWS Managed Rules (Core, SQL injection, XSS)
  - **CORS específico**: whitelist de orígenes (`https://turnaki.nexioq.com`, `http://localhost:5173` solo en dev)
  - **JWT authorizer** con Cognito, scopes por endpoint
  - Throttling: 10,000 req/s burst, 5,000 req/s steady-state
- **CloudFront**: 
  - Security headers policy (CSP, HSTS 1 año, X-Frame-Options DENY, X-Content-Type-Options nosniff)
  - TLS 1.2+ mínimo, cipher suites modernos
  - OAI (Origin Access Identity) para S3 privado; migración a OAC planificada
- **Secrets Manager**: rotación automática de API keys, DB credentials (futuro RDS/Aurora)
- **IAM**: mínimo privilegio, roles por función (no usuarios), OIDC trust para CI/CD (GitHub Actions)
- **Verified Permissions (Cedar)** para ABAC/RBAC fino y auditoría de decisiones
- **Emails autenticados**: SES con Easy DKIM (SPF, DKIM, DMARC), suppression list gestionada
- **Logs**: sanitización de datos sensibles (PII), cifrado en reposo (KMS), retención limitada (7-30 días)
- **Compliance**: auditoría de accesos (CloudTrail), encriptación en tránsito y reposo, GDPR-ready (data retention policies)

### 4.4 Infra como código (CDK v2)
- **Versión**: AWS CDK 2.150+ (ESM modules, Node.js 20+)
- **Bootstrap**: qualifier custom `turnaki`, toolkit stack `TurnakiCDKToolkit`, assets bucket `cdk-turnaki-assets-<account>-<region>`
- **Naming convention**: prefijo `tk-nq` en todos los recursos (Lambdas, API, buckets, roles, topics)
- **Stacks implementados (MVP)**:
  - `DevStack`: API Gateway HTTP + Lambdas (health, availability), CORS, outputs (HttpApiUrl)
  - `FrontendStack`: S3 privado + CloudFront + Route53 + ACM + IAM OIDC role, outputs (BucketName, DistributionId, FrontendUrl)
- **Stacks planificados (MMP)**:
  - `AuthStack`: Cognito User Pool + Identity Pool + JWT authorizer
  - `DataStack`: DynamoDB single-table + GSIs + streams + backup vault
  - `NotificationsStack`: EventBridge Scheduler + SES + Pinpoint + SQS FIFO
  - `ObservabilityStack`: CloudWatch Dashboard + Alarmas SNS + X-Ray groups + OpenSearch (opcional)
  - `PipelineStack`: CDK Pipelines (self-mutating) con stages dev/stage/prod, approval manual en prod
- **Multi-stage**: variable `STAGE` (env) determina sufijos de stack, retention policies, monitoring level
- **Parametrización**: SSM Parameter Store para config runtime (`/tk-nq/{stage}/config/*`)
- **Feature flags**: AWS AppConfig para rollout gradual, kill switches
- **Constructos**: L2/L3 preferidos, L1 (Cfn) solo para features beta (ej: Verified Permissions)
- **Testing infra**: CDK assertions (`@aws-cdk/assertions`), snapshot tests
- **Deployment**: 
  - Local: `cdk deploy` con context/qualifier
  - CI/CD: GitHub Actions OIDC → assume role → cdk deploy (sin credenciales en secrets)

---

## API (endpoints clave — ejemplos)
- `POST /booking/availability` → calcula *slots* por sede/profesional/recurso.  
- `POST /booking/reservations` → crea cita con `TransactWriteItems` (clave idempotente).  
- `PATCH /booking/reservations/{id}` → reprograma (valida conflictos).  
- `POST /notifications/schedules` → programa recordatorio (crea *schedule* en EventBridge Scheduler).

---

## Modelo de datos single‑table (ejemplos)
- **PK** = `TENANT#<t>` · **SK** = `CITA#<fecha>#<recurso>#<id>`  
- **Slot**: `PK=TENANT#t#SEDE#s#FECHA#2025-08-12` · `SK=RECURSO#chair-2#HORA#10:00`  
  Condición: `attribute_not_exists(SK)` al reservar.  
- **GSI1**: consultas por profesional y rango de fechas.  
- **TTL**: tokens y colaterales.

---

## Flujos operativos
1) **Búsqueda de disponibilidad** → consulta por sede/profesional/recurso y tipo de tratamiento (aplica buffers).  
2) **Reserva** → transacción atómica; si falla la condición, devolver alternativas.  
3) **Recordatorios** → *schedules* T‑24h/T‑2h; al disparar, Lambda envía por SES/Pinpoint.  
4) **No‑show** → marca estado y re‑agenda por lista de espera.

---

## Operación, calidad y costes
- **Observabilidad**: trazas distribuidas y métricas por tenant; alarmas (p99 de confirmación < umbral definido).  
- **Pruebas**: unitarias (Rust), contract (Pact) y e2e (Playwright); *load testing* con k6.  
- **Costes**: serverless con escala a cero en horas valle; SQS/SES/Pinpoint según volumen (alertas de gasto).  
- **Caché CDN** para *assets*; invalidación por versión.

---

## Beneficios clave
- **Cero *overbooking*** gracias a condiciones transaccionales en DynamoDB.  
- **Recordatorios robustos** con EventBridge Scheduler (eventos únicos y recurrentes, *retry policies*).  
- **Entrega rápida y segura del front** con CloudFront + OAC y *security headers*.  
- **Configuración e IAM desde la UI** con versionado, auditoría y *rollback*.

---

## Próximos pasos sugeridos

### ✅ Completado (MVP inicial desplegado)
1. ✅ Monorepo con workspaces (frontend, infra, backend)
2. ✅ CDK stacks base: `DevStack` (API + Lambdas), `FrontendStack` (S3 + CloudFront + Route53)
3. ✅ Backend Rust: handlers `health` y `availability` (mock), compilación ARM64 AL2023
4. ✅ Frontend SvelteKit 5 + Vite 7: build estático, preview local
5. ✅ Deploy exitoso: API operativa, frontend en validación DNS (turnaki.nexioq.com)
6. ✅ Documentación: README, RUNBOOK, análisis de mejoras (MEJORAS_PROPUESTAS.md)

### 🔄 En curso
- **FrontendStack**: esperando validación ACM (5-10 min), luego sync a S3 + invalidación CloudFront

### 📋 Sprint 1 (siguiente, 2 semanas) — Fundaciones de calidad
Implementación de `MEJORAS_PROPUESTAS.md` Sprint 1:
1. **Testing básico**: unitarios en Rust (health, availability), fixtures, mocks
2. **Linting**: ESLint + Prettier (frontend), rustfmt + clippy (backend), pre-commit hooks
3. **Shared library Rust**: error handling, response builders, tracing, validación
4. **CI básico**: GitHub Actions (lint + test en PR, cache de deps)
5. **CORS específico**: quitar wildcard, lista blanca de dominios
6. **Validación de inputs**: validator crate en availability
7. **X-Ray**: habilitar tracing ACTIVE en Lambdas CDK

### 📋 Sprint 2 (2 semanas) — Seguridad y persistencia
8. WAF en API Gateway (rate limit + AWS Managed Rules)
9. Alarmas CloudWatch (errors, latency) + SNS topic
10. DynamoDB single-table + GSIs (tenant isolation)
11. TypeScript en frontend + migración completa a Runes
12. PWA completo (manifest, service worker, offline mode)
13. Frontend CD: GitHub Actions → S3 + CloudFront invalidation automática
14. Pre-commit hooks (Husky + lint-staged)

### 📋 Sprint 3+ (MMP) — Features avanzadas
15. Cognito User Pool + JWT authorizer + MFA
16. Centro de Configuración UI (versionado, rollback, simulador)
17. Módulo IAM UI (usuarios, roles, políticas Cedar, simulador)
18. EventBridge Scheduler + SES/Pinpoint (recordatorios T-24h/T-2h)
19. Motor de reservas real (disponibilidad, reserva atómica con TransactWriteItems)
20. Portal paciente completo (booking wizard 3 pasos, mis citas, perfil)
21. Back-office agenda (día/semana/mes, drag & drop con validación)
22. Multi-stage completo (dev/stage/prod con CDK Pipelines)
23. Experimentos A/B (AppConfig) y módulo IA (sugerencias de slots óptimos)

---

## Referencias técnicas

### Verificadas en implementación MVP (2025-08-12)
- **Rust**: [Rust 1.89.0 release](https://blog.rust-lang.org/), [lambda_http 0.13 docs](https://docs.rs/lambda_http/0.13)
- **Cargo Lambda**: [github.com/cargo-lambda/cargo-lambda](https://github.com/cargo-lambda/cargo-lambda) — v1.8.6 estable
- **AWS Lambda Rust Runtime**: [github.com/awslabs/aws-lambda-rust-runtime](https://github.com/awslabs/aws-lambda-rust-runtime)
- **SvelteKit**: [kit.svelte.dev](https://kit.svelte.dev) — v2.28.0, [Svelte 5 Runes](https://svelte.dev/docs/svelte/what-are-runes)
- **Vite**: [vitejs.dev](https://vitejs.dev) — v7.1.2, [vite-plugin-pwa](https://vite-pwa-org.netlify.app/)
- **AWS CDK**: [docs.aws.amazon.com/cdk](https://docs.aws.amazon.com/cdk/v2/guide) — v2.150+, [CDK Patterns](https://cdkpatterns.com/)
- **API Gateway HTTP API**: [docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
- **DynamoDB single-table**: [AWS re:Invent 2019 - Advanced Design Patterns](https://www.youtube.com/watch?v=HaEPXoXVf2k)
- **EventBridge Scheduler**: [docs.aws.amazon.com/scheduler](https://docs.aws.amazon.com/scheduler/latest/UserGuide/)
- **SES (Easy DKIM)**: [docs.aws.amazon.com/ses/latest/dg/send-email-authentication-dkim-easy.html](https://docs.aws.amazon.com/ses/latest/dg/send-email-authentication-dkim-easy.html)
- **CloudFront + ACM**: [Using ACM with CloudFront](https://docs.aws.amazon.com/acm/latest/userguide/acm-services.html)
- **GitHub Actions OIDC**: [docs.github.com/actions/deployment/security-hardening](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- **AWS Well-Architected Serverless**: [Serverless Lens](https://docs.aws.amazon.com/wellarchitected/latest/serverless-applications-lens/)

### Herramientas de desarrollo
- **Testing**: [Vitest](https://vitest.dev/), [Playwright](https://playwright.dev/), [cargo-nextest](https://nexte.st/)
- **Linting**: [ESLint](https://eslint.org/), [Prettier](https://prettier.io/), [clippy](https://github.com/rust-lang/rust-clippy)
- **Observabilidad**: [AWS X-Ray](https://aws.amazon.com/xray/), [CloudWatch Embedded Metric Format](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format.html)

### Repositorio del proyecto
- **GitHub**: [turnaki-nexioq](https://github.com/<org>/turnaki-nexioq) (privado)
- **Documentación viva**: README.md, infra/RUNBOOK.md, MEJORAS_PROPUESTAS.md
- **Endpoints desplegados**:
  - API: https://6s12of1wyd.execute-api.us-east-1.amazonaws.com
  - Frontend: https://turnaki.nexioq.com (en validación DNS)
  - Preview local: http://localhost:5173

