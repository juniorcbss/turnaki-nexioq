# 🏗️ Arquitectura Técnica

---

## Resumen

**Turnaki-NexioQ** es un sistema SaaS multi-tenant de reservas odontológicas construido con arquitectura serverless en AWS.

---

## Stack Tecnológico

| Capa | Tecnología | Justificación |
|------|------------|---------------|
| **Frontend** | SvelteKit 5 + TypeScript | Reactive, performante, TypeScript para type-safety |
| **Backend** | Rust 1.89 + AWS Lambda | Alta performance, bajo costo, memory-safe |
| **API Gateway** | AWS HTTP API | Bajo costo, JWT authorizer nativo |
| **Database** | DynamoDB | Serverless, escalable, single-table design |
| **Auth** | Cognito User Pool | Managed auth, OAuth 2.0, JWT tokens |
| **CDN** | CloudFront | Cache global, HTTPS, custom domain |
| **IaC** | Terraform 1.9 | Multi-ambiente, módulos reutilizables, state management |
| **Monitoring** | CloudWatch + X-Ray | Logs, métricas, trazas distribuidas |

---

## Diagrama de Arquitectura

```
┌─────────────┐
│   Usuario   │
└──────┬──────┘
       │ HTTPS
       ↓
┌──────────────────┐
│   CloudFront     │ ← ACM Certificate
│   + S3 (SPA)     │
└──────┬───────────┘
       │
       ↓
┌──────────────────┐
│   Route53 DNS    │
└──────────────────┘
       │
       ↓
┌──────────────────┐
│  API Gateway     │ ← WAF
│  (HTTP API)      │
└──────┬───────────┘
       │ JWT Auth
       ↓
┌──────────────────┐
│  Cognito         │
│  User Pool       │
└──────────────────┘
       │
       ↓
┌──────────────────────────────────────┐
│         Lambda Functions             │
│  ┌──────┐ ┌──────┐ ┌──────┐         │
│  │Health│ │Bookng│ │Availb│ ...     │
│  └──────┘ └──────┘ └──────┘         │
│  (Rust + ARM64)                      │
└──────┬───────────────────────────────┘
       │
       ↓
┌──────────────────┐
│   DynamoDB       │
│  (Single Table)  │
│  + GSI1, GSI2    │
└──────────────────┘
       │
       ↓
┌──────────────────┐
│  EventBridge     │
│  (Reminders)     │
└──────────────────┘
       │
       ↓
┌──────────────────┐
│      SES         │
│  (Emails)        │
└──────────────────┘
```

---

## Base de Datos: DynamoDB Single-Table

### Diseño de Clave Primaria

| Entidad | PK | SK | Atributos |
|---------|----|----|-----------|
| **Tenant** | `TENANT#<id>` | `METADATA` | name, email, phone |
| **Treatment** | `TENANT#<id>` | `TREATMENT#<id>` | name, duration, price |
| **Professional** | `TENANT#<id>` | `PROFESSIONAL#<id>` | name, specialty, email |
| **Booking** | `TENANT#<id>` | `BOOKING#<id>` | patient_id, treatment_id, date_time, status |
| **Slot** | `TENANT#<id>` | `SLOT#<date>#<time>#<prof_id>` | available, locked_until |

### Global Secondary Indexes

#### GSI1 - By Patient

- **GSI1PK**: `PATIENT#<id>`
- **GSI1SK**: `BOOKING#<date>`
- **Uso**: Listar todas las citas de un paciente

#### GSI2 - By Professional

- **GSI2PK**: `PROFESSIONAL#<id>`
- **GSI2SK**: `BOOKING#<date>`
- **Uso**: Listar agenda de un profesional

---

## Backend: Lambdas Rust

### Funciones Implementadas

1. **health** - Health check
2. **availability** - Consultar slots disponibles
3. **bookings** - CRUD de reservas + transacciones atómicas
4. **tenants** - CRUD de clínicas
5. **treatments** - CRUD de tratamientos
6. **professionals** - CRUD de profesionales
7. **send-notification** - Envío de emails
8. **schedule-reminder** - Recordatorios automáticos

### Shared Library

```rust
// backend/shared-lib/src/
├── error.rs         # Custom errors + conversión a HTTP
├── response.rs      # Response builders
├── dynamodb.rs      # DynamoDB client + helpers
└── tracing.rs       # Logging estructurado
```

---

## Frontend: SvelteKit

### Estructura

```
frontend/src/
├── lib/
│   ├── api.svelte.ts       # API client
│   └── auth.svelte.ts      # Auth store
└── routes/
    ├── +page.svelte        # Home
    ├── booking/            # Wizard 3 pasos
    ├── my-appointments/    # Portal paciente
    ├── admin/              # Panel admin
    └── calendar/           # Calendario back-office
```

### Features

- ✅ PWA (offline-ready, installable)
- ✅ Svelte 5 Runes ($state, $derived, $effect)
- ✅ TypeScript
- ✅ TailwindCSS (inline)
- ✅ FullCalendar integration

---

## Autenticación

### Flujo OAuth 2.0

1. Usuario → Click "Iniciar sesión"
2. Redirect a Cognito Hosted UI
3. Usuario ingresa credenciales
4. Cognito redirect con `code`
5. Frontend exchange code por tokens
6. Tokens guardados en localStorage
7. Token incluido en requests: `Authorization: Bearer <token>`
8. API Gateway valida JWT automáticamente

### Roles

- **Owner**: Acceso total, multi-tenant
- **Admin**: CRUD en su tenant
- **Odontólogo**: Ver citas, gestionar agenda
- **Recepción**: Crear/editar citas
- **Paciente**: Reservar citas, ver historial

---

## Motor de Reservas (Sin Overbooking)

### Transacción Atómica

```rust
// DynamoDB TransactWriteItems
let items = vec![
    TransactWriteItem::builder()
        .put(/* Slot */)
        .condition_expression("attribute_not_exists(PK)")
        .build()?,
    TransactWriteItem::builder()
        .put(/* Booking */)
        .build()?,
];

client.transact_write_items()
    .transact_items(items)
    .send()
    .await?;
```

**Garantía**: Si el slot ya fue reservado, la transacción completa falla (409 Conflict).

---

## Infraestructura: Terraform

### Módulos Reutilizables

```
terraform/modules/
├── iam/              # Roles y políticas
├── dynamodb/         # Tablas + GSIs
├── cognito/          # User Pool + Client
├── lambda/           # Funciones genéricas
├── api-gateway/      # HTTP API + Authorizer
├── s3-cloudfront/    # Frontend hosting
├── waf/              # Protección DDoS
├── cloudwatch/       # Dashboard + Alarmas
└── ses/              # Email sending
```

### Ambientes

- **dev**: Desarrollo, sin retención de recursos
- **qas**: Testing, retención parcial
- **prd**: Producción, retención completa, backups

---

## Observabilidad

### CloudWatch Logs

- `/aws/lambda/<function-name>`
- Retención: 7 días (dev), 30 días (prd)
- Structured logging (JSON)

### CloudWatch Metrics

- Lambda invocations, errors, duration
- API Gateway requests, 4xx, 5xx
- DynamoDB read/write capacity

### CloudWatch Alarmas

- Health errors > 1 en 5 min → SNS
- Bookings p99 latency > 3s → SNS
- DynamoDB throttles > 10 → SNS

### X-Ray Tracing

- Habilitado en todas las Lambdas
- Service map
- Trace analysis

---

## Seguridad

### Implementado

- ✅ WAF v2 con rate limiting (2000 req/5min)
- ✅ JWT Authorizer en API Gateway
- ✅ Cognito con MFA opcional
- ✅ Encryption at rest (DynamoDB, S3)
- ✅ Encryption in transit (HTTPS, TLS 1.2+)
- ✅ IAM policies de mínimo privilegio
- ✅ X-Ray tracing
- ✅ CloudWatch Logs
- ✅ CORS whitelist específico

### Pendiente

- ⏸️ AWS Verified Permissions (ABAC/RBAC fino)
- ⏸️ Secrets Manager para credenciales
- ⏸️ GuardDuty
- ⏸️ Security Hub

---

## Costos Estimados

### Pay-per-request

- Lambda ARM64: ~$0.20/millón requests
- DynamoDB: $1.25/millón writes, $0.25/millón reads
- API Gateway: $1.00/millón requests
- SES: $0.10/1,000 emails
- CloudFront: $0.085/GB

### Fijos

- WAF: ~$10/mes
- CloudWatch: ~$5/mes
- Route53: $0.50/hosted zone

### Total

- **Dev**: $15-25/mes
- **Prd (100 usuarios)**: $30-50/mes
- **Prd (1,000 usuarios)**: $150-200/mes

---

## Escalabilidad

### Límites Actuales

- Lambda: 1000 concurrent executions
- DynamoDB: 40,000 RCU/WCU (on-demand)
- API Gateway: 10,000 req/s
- Cognito: 120 req/s (soft limit)

### Estrategia de Escalamiento

1. **Lambda**: Auto-scaling horizontal, provisioned concurrency si es necesario
2. **DynamoDB**: On-demand billing, auto-scaling
3. **API Gateway**: Sin límite (pagar por uso)
4. **CloudFront**: Global, auto-scaling

---

## Disaster Recovery

### RPO/RTO

- **RPO**: <15 minutos (PITR de DynamoDB)
- **RTO**: <1 hora (redeploy con Terraform)

### Backups

- DynamoDB PITR habilitado
- Terraform state en S3 (versionado)
- Código en Git

### Multi-Región (Futuro)

- DynamoDB Global Tables
- Lambda multi-región
- Route53 failover

---

**Última actualización**: Octubre 2025  
**Versión**: 2.0.0
