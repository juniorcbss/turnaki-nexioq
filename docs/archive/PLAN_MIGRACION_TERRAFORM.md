# 🚀 Plan de Migración a Terraform + IaC

**Proyecto**: Turnaki-NexioQ  
**Fecha**: 3 de Octubre 2025  
**Objetivo**: Migrar de AWS CDK a Terraform con arquitectura multi-ambiente y módulos reutilizables

---

## 📋 Tabla de Contenidos

1. [Análisis del Estado Actual](#análisis-del-estado-actual)
2. [Nueva Estructura Propuesta](#nueva-estructura-propuesta)
3. [Arquitectura de Módulos](#arquitectura-de-módulos)
4. [Plan de Limpieza](#plan-de-limpieza)
5. [Plan de Documentación](#plan-de-documentación)
6. [Roadmap de Migración](#roadmap-de-migración)
7. [Checklist de Implementación](#checklist-de-implementación)

---

## 🔍 Análisis del Estado Actual

### Infraestructura Actual (CDK)
```
infra/
├── bin/cli.mjs              # Entry point CDK
├── src/stacks/
│   ├── auth-stack.js        # Cognito User Pool
│   ├── data-stack.js        # DynamoDB
│   ├── dev-stack.js         # API Gateway + Lambdas
│   ├── frontend-stack.js    # S3 + CloudFront
│   ├── notifications-stack.js
│   ├── observability-stack.js
│   └── waf-stack.js
├── assets/lambda/*.zip      # Binarios Lambda
└── cdk.out/                 # CloudFormation generado
```

### Problemas Identificados

1. **No hay separación de ambientes** (dev/qas/prd)
2. **No hay reutilización** - cada stack es único
3. **Dependencias mixtas** - CDK JavaScript + Rust + Svelte
4. **Documentación fragmentada** - 12 archivos .md en raíz
5. **Archivos obsoletos** - cdk.out/, test-results/, node_modules en raíz
6. **Sin GitOps** - deploys manuales

---

## 🏗️ Nueva Estructura Propuesta

### Estructura de Directorios Terraform

```
turnaki-nexioq/
│
├── terraform/                           # ⭐ Nuevo: Infraestructura como código
│   │
│   ├── modules/                         # Módulos reutilizables
│   │   ├── iam/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   │
│   │   ├── dynamodb/
│   │   │   ├── main.tf                 # Tabla + GSIs
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   │
│   │   ├── cognito/
│   │   │   ├── main.tf                 # User Pool + Client + Domain
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   │
│   │   ├── api-gateway/
│   │   │   ├── main.tf                 # HTTP API + Authorizer + Routes
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   │
│   │   ├── lambda/
│   │   │   ├── main.tf                 # Lambda Function + LogGroup
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   │
│   │   ├── s3-cloudfront/
│   │   │   ├── main.tf                 # S3 + CloudFront + OAI
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   │
│   │   ├── waf/
│   │   │   ├── main.tf                 # WAFv2 + Rate Limiting
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   │
│   │   ├── cloudwatch/
│   │   │   ├── main.tf                 # Dashboard + Alarmas + SNS
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   │
│   │   └── ses/
│   │       ├── main.tf                 # SES Domain + Identity
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── README.md
│   │
│   ├── environments/                    # Configuraciones por ambiente
│   │   │
│   │   ├── dev/
│   │   │   ├── main.tf                 # Orquestador de módulos
│   │   │   ├── variables.tf
│   │   │   ├── terraform.tfvars        # Valores dev
│   │   │   ├── backend.tf              # S3 backend config
│   │   │   └── outputs.tf
│   │   │
│   │   ├── qas/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── terraform.tfvars        # Valores qas
│   │   │   ├── backend.tf
│   │   │   └── outputs.tf
│   │   │
│   │   └── prd/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── terraform.tfvars        # Valores prd
│   │       ├── backend.tf
│   │       └── outputs.tf
│   │
│   ├── scripts/
│   │   ├── init-backend.sh             # Crear S3 + DynamoDB para tfstate
│   │   ├── plan-all.sh                 # terraform plan en todos los ambientes
│   │   ├── apply-dev.sh
│   │   ├── apply-qas.sh
│   │   ├── apply-prd.sh
│   │   └── destroy-dev.sh
│   │
│   ├── .terraform.lock.hcl              # Lock file
│   ├── .gitignore
│   └── README.md                        # Documentación IaC
│
├── backend/                             # ⚙️ Rust Lambdas (sin cambios)
│   ├── functions/
│   │   ├── availability/
│   │   ├── bookings/
│   │   ├── health/
│   │   ├── professionals/
│   │   ├── schedule-reminder/
│   │   ├── send-notification/
│   │   ├── tenants/
│   │   └── treatments/
│   ├── shared-lib/
│   ├── Cargo.toml
│   └── Cargo.lock
│
├── frontend/                            # 🎨 Svelte (sin cambios)
│   ├── src/
│   ├── e2e/
│   ├── static/
│   ├── package.json
│   └── vite.config.js
│
├── docs/                                # 📚 Documentación unificada
│   ├── README.md                        # Índice de documentación
│   ├── ARCHITECTURE.md                  # Arquitectura técnica
│   ├── DEPLOYMENT.md                    # Guía de deployment
│   ├── RUNBOOK.md                       # Operaciones y troubleshooting
│   ├── DEVELOPMENT.md                   # Guía para desarrolladores
│   ├── API.md                           # Especificación API
│   ├── TESTING.md                       # Testing E2E y unitario
│   └── CHANGELOG.md                     # Historial de cambios
│
├── scripts/                             # 🔧 Scripts operativos
│   ├── build-lambdas.sh                 # Build Rust -> Lambda
│   ├── deploy-frontend.sh               # Build + Upload S3
│   ├── seed-database.sh                 # Seed DynamoDB
│   └── verify-health.sh                 # Health checks
│
├── .github/                             # 🔄 CI/CD (opcional)
│   └── workflows/
│       ├── terraform-plan.yml           # Plan on PR
│       ├── terraform-apply-dev.yml      # Auto-deploy dev
│       ├── backend-test.yml             # Cargo test
│       └── frontend-e2e.yml             # Playwright
│
├── .gitignore
├── .cursorignore
├── package.json                         # Root workspace
├── README.md                            # README principal
└── LICENSE
```

---

## 🧩 Arquitectura de Módulos

### 1. Módulo `iam`

**Propósito**: Roles y políticas IAM reutilizables

```hcl
# terraform/modules/iam/main.tf
resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-${var.environment}-lambda-${var.function_name}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-lambda-${var.function_name}"
    Environment = var.environment
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Política personalizada para DynamoDB
resource "aws_iam_role_policy" "dynamodb_access" {
  count = var.dynamodb_table_arn != null ? 1 : 0
  role  = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      }
    ]
  })
}
```

### 2. Módulo `dynamodb`

**Propósito**: Single-table design con GSIs

```hcl
# terraform/modules/dynamodb/main.tf
resource "aws_dynamodb_table" "main" {
  name           = "${var.project_name}-${var.environment}-main"
  billing_mode   = var.billing_mode
  hash_key       = "PK"
  range_key      = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  attribute {
    name = "GSI2PK"
    type = "S"
  }

  attribute {
    name = "GSI2SK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "GSI2"
    hash_key        = "GSI2PK"
    range_key       = "GSI2SK"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-main"
    Environment = var.environment
  })
}
```

### 3. Módulo `cognito`

**Propósito**: User Pool completo con Hosted UI

```hcl
# terraform/modules/cognito/main.tf
resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-${var.environment}-users"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  schema {
    name                = "tenant_id"
    attribute_data_type = "String"
    mutable             = true
  }

  schema {
    name                = "role"
    attribute_data_type = "String"
    mutable             = true
  }

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-${var.environment}-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_pool_client" "main" {
  name                         = "${var.project_name}-${var.environment}-client"
  user_pool_id                 = aws_cognito_user_pool.main.id
  generate_secret              = false
  refresh_token_validity       = 30
  access_token_validity        = 1
  id_token_validity            = 1
  token_validity_units {
    refresh_token = "days"
    access_token  = "hours"
    id_token      = "hours"
  }

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_CUSTOM_AUTH"
  ]
}
```

### 4. Módulo `lambda`

**Propósito**: Lambda Function genérica

```hcl
# terraform/modules/lambda/main.tf
resource "aws_lambda_function" "function" {
  function_name = "${var.project_name}-${var.environment}-${var.function_name}"
  role          = var.iam_role_arn
  handler       = "bootstrap"
  runtime       = "provided.al2023"
  architectures = ["arm64"]

  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  timeout     = var.timeout
  memory_size = var.memory_size

  environment {
    variables = merge(
      {
        RUST_LOG   = var.log_level
        LOG_LEVEL  = var.log_level
        TABLE_NAME = var.dynamodb_table_name
      },
      var.environment_variables
    )
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-${var.function_name}"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_log_group" "function" {
  name              = "/aws/lambda/${aws_lambda_function.function.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Environment = var.environment
  })
}
```

### 5. Módulo `api-gateway`

**Propósito**: HTTP API con JWT Authorizer

```hcl
# terraform/modules/api-gateway/main.tf
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["authorization", "content-type", "x-amz-date"]
    allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_origins = var.cors_allowed_origins
    max_age       = 3600
  }

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-jwt"

  jwt_configuration {
    audience = [var.cognito_client_id]
    issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${var.cognito_user_pool_id}"
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = var.throttle_burst_limit
    throttling_rate_limit  = var.throttle_rate_limit
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.main.name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Environment = var.environment
  })
}
```

---

## 🧹 Plan de Limpieza

### Archivos a ELIMINAR

```bash
# CDK (obsoleto)
rm -rf infra/
rm -rf node_modules/  # En raíz si existe

# Build artifacts
rm -rf backend/target/debug/
rm -rf backend/target/tmp/
rm -rf frontend/build/
rm -rf frontend/playwright-report/
rm -rf frontend/test-results/

# Documentación obsoleta (consolidar antes)
# Se moverán a docs/ y se consolidarán
```

### Archivos a MOVER

```bash
# Documentación -> docs/
ANALISIS_GAP_IMPLEMENTACION.md      -> docs/archive/
COMO_HACER_LOGIN.md                  -> docs/AUTHENTICATION.md (consolidar)
ESTADO_FINAL_MVP.md                  -> docs/archive/
MEJORAS_PROPUESTAS.md                -> docs/ROADMAP.md (consolidar)
RESUMEN_FINAL.md                     -> docs/archive/
SISTEMA_100_COMPLETADO.md            -> docs/archive/
SISTEMA_COMPLETO_FINAL.md            -> docs/ARCHITECTURE.md (consolidar)
SPRINT1_COMPLETADO.md                -> docs/archive/
TESTING_COMPLETO.md                  -> docs/TESTING.md (consolidar)
backlog_y_sprints_reserva_odontologica_saa_s.md -> docs/BACKLOG.md
reserva_de_citas_odontologicas_saa_s.md -> docs/archive/

# Infraestructura
infra/RUNBOOK.md                     -> docs/RUNBOOK.md
```

### Archivos a ACTUALIZAR

```bash
# README.md principal
- Quitar sección "Infraestructura (AWS CDK)"
- Agregar sección "Infraestructura (Terraform)"
- Actualizar comandos de deploy
- Actualizar badges

# .gitignore
+ terraform/.terraform/
+ terraform/**/.terraform.lock.hcl
+ terraform/**/*.tfstate
+ terraform/**/*.tfstate.backup
+ terraform/**/.terraform.tfstate.lock.info
```

---

## 📚 Plan de Documentación

### Nueva Estructura docs/

```
docs/
├── README.md                    # Índice y guía rápida
├── ARCHITECTURE.md              # Consolidación de:
│                                # - SISTEMA_COMPLETO_FINAL.md
│                                # - Arquitectura de lambdas
│                                # - DynamoDB schema
│                                # - Diagramas de flujo
│
├── DEPLOYMENT.md                # Consolidación de:
│                                # - Deployment con Terraform
│                                # - Multi-ambiente (dev/qas/prd)
│                                # - Rollback procedures
│
├── RUNBOOK.md                   # Consolidación de:
│                                # - infra/RUNBOOK.md
│                                # - Troubleshooting común
│                                # - Comandos operativos
│
├── DEVELOPMENT.md               # Consolidación de:
│                                # - Setup local
│                                # - Como ejecutar tests
│                                # - Build lambdas
│
├── AUTHENTICATION.md            # Consolidación de:
│                                # - COMO_HACER_LOGIN.md
│                                # - Flujo OAuth
│                                # - Configuración Cognito
│
├── API.md                       # Especificación completa API
│                                # - Endpoints
│                                # - Request/Response
│                                # - Códigos de error
│
├── TESTING.md                   # Consolidación de:
│                                # - TESTING_COMPLETO.md
│                                # - E2E Playwright
│                                # - Unit tests Rust
│
├── ROADMAP.md                   # Consolidación de:
│                                # - MEJORAS_PROPUESTAS.md
│                                # - Features pendientes
│
├── CHANGELOG.md                 # Historial de versiones
│
└── archive/                     # Documentos históricos
    ├── ANALISIS_GAP_IMPLEMENTACION.md
    ├── ESTADO_FINAL_MVP.md
    ├── RESUMEN_FINAL.md
    ├── SISTEMA_100_COMPLETADO.md
    ├── SPRINT1_COMPLETADO.md
    └── reserva_de_citas_odontologicas_saa_s.md
```

### Plantilla README.md Principal (actualizado)

```markdown
# 🦷 Turnaki-NexioQ

**Sistema SaaS Multi-Tenant de Reservas Odontológicas**

[![Status](https://img.shields.io/badge/Status-Production%20Ready-success)](.)`
[![Backend](https://img.shields.io/badge/Backend-Rust%201.89-orange)](https://www.rust-lang.org/)
[![Frontend](https://img.shields.io/badge/Frontend-Svelte%205-ff3e00)](https://svelte.dev/)
[![Infrastructure](https://img.shields.io/badge/IaC-Terraform-844FBA)](https://www.terraform.io/)

---

## 🚀 Quick Start

### Prerrequisitos
- Terraform >= 1.9
- AWS CLI configurado
- Node.js >= 20
- Rust >= 1.75
- Cargo Lambda

### Deployment

```bash
# 1. Inicializar backend de Terraform
cd terraform
./scripts/init-backend.sh

# 2. Deploy ambiente dev
cd environments/dev
terraform init
terraform plan
terraform apply

# 3. Build y deploy lambdas
cd ../../../backend
cargo lambda build --arm64 --release
./deploy-lambdas.sh dev

# 4. Deploy frontend
cd ../frontend
npm run build
aws s3 sync build/ s3://tk-nq-dev-frontend/
```

### Desarrollo Local

```bash
# Frontend
cd frontend
npm run dev
# http://localhost:5173

# Backend (tests)
cd backend
cargo test --workspace
```

---

## 📚 Documentación

- **[Arquitectura](docs/ARCHITECTURE.md)** - Diseño técnico y diagramas
- **[Deployment](docs/DEPLOYMENT.md)** - Guía de deployment con Terraform
- **[Desarrollo](docs/DEVELOPMENT.md)** - Setup y desarrollo local
- **[API](docs/API.md)** - Especificación de endpoints
- **[Testing](docs/TESTING.md)** - E2E y unit testing
- **[Runbook](docs/RUNBOOK.md)** - Operaciones y troubleshooting

---

## 🏗️ Stack Tecnológico

| Capa | Tecnología |
|------|------------|
| **Frontend** | SvelteKit 5 + TypeScript + TailwindCSS |
| **Backend** | Rust 1.89 + AWS Lambda |
| **Database** | DynamoDB (single-table) |
| **Auth** | Cognito User Pool + JWT |
| **IaC** | Terraform 1.9 |
| **CI/CD** | GitHub Actions |
| **Monitoring** | CloudWatch + X-Ray |

---

## 📊 Ambientes

| Ambiente | URL | Estado |
|----------|-----|--------|
| **Dev** | https://dev.turnaki.nexioq.com | ✅ Activo |
| **QAS** | https://qas.turnaki.nexioq.com | 🚧 Próximamente |
| **PRD** | https://turnaki.nexioq.com | ⏸️ Pendiente |

---

## 📄 Licencia

MIT License
```

---

## 🛤️ Roadmap de Migración

### Fase 1: Preparación (1-2 días)

**Objetivos**:
- ✅ Crear estructura de carpetas Terraform
- ✅ Documentar infraestructura CDK actual
- ✅ Crear plan de migración detallado

**Tareas**:
1. Crear carpeta `terraform/` con subcarpetas
2. Documentar outputs de CDK actual:
   ```bash
   cd infra
   npx cdk synth --all > ../CDK_CURRENT_STATE.json
   aws cloudformation describe-stacks --region us-east-1 > ../CURRENT_STACKS.json
   ```
3. Inventariar recursos AWS actuales
4. Crear módulos base en Terraform

### Fase 2: Módulos Base (2-3 días)

**Objetivos**:
- ✅ Crear módulos reutilizables
- ✅ Implementar variables y outputs
- ✅ Documentar cada módulo

**Orden de Implementación**:
1. `iam` - Roles básicos
2. `dynamodb` - Tabla con GSIs
3. `cognito` - User Pool + Client
4. `lambda` - Función genérica
5. `api-gateway` - HTTP API
6. `s3-cloudfront` - Frontend hosting
7. `waf` - Protección
8. `cloudwatch` - Observabilidad
9. `ses` - Emails

### Fase 3: Ambiente Dev (2-3 días)

**Objetivos**:
- ✅ Configurar ambiente dev completo
- ✅ Migrar recursos de CDK a Terraform
- ✅ Validar funcionamiento

**Tareas**:
1. Crear `terraform/environments/dev/main.tf`
2. Configurar backend S3 para tfstate
3. Crear `terraform.tfvars` con valores dev
4. Ejecutar `terraform import` de recursos existentes (opcional)
5. Deploy paralelo (mantener CDK activo)
6. Testing exhaustivo
7. Cambiar DNS a nuevo API Gateway
8. Destruir stack CDK

### Fase 4: Ambientes QAS y PRD (2 días)

**Objetivos**:
- ✅ Replicar configuración a qas
- ✅ Preparar ambiente prd
- ✅ Documentar diferencias

**Tareas**:
1. Copiar estructura dev -> qas
2. Ajustar `terraform.tfvars` para qas
3. Deploy ambiente qas
4. Testing en qas
5. Preparar prd (sin deploy aún)

### Fase 5: Limpieza y Documentación (1-2 días)

**Objetivos**:
- ✅ Eliminar CDK
- ✅ Consolidar documentación
- ✅ Actualizar README

**Tareas**:
1. Ejecutar plan de limpieza
2. Mover documentación a `docs/`
3. Consolidar archivos .md
4. Actualizar README principal
5. Crear CHANGELOG.md
6. Actualizar .gitignore

### Fase 6: CI/CD (Opcional, 1-2 días)

**Objetivos**:
- ✅ Automatizar Terraform
- ✅ Integrar con GitHub Actions

**Tareas**:
1. Crear `.github/workflows/terraform-plan.yml`
2. Crear `.github/workflows/terraform-apply-dev.yml`
3. Configurar secrets de AWS
4. Testing de workflows

---

## ✅ Checklist de Implementación

### Pre-Migración
- [ ] Backup de infraestructura actual
- [ ] Documentar dependencias entre stacks CDK
- [ ] Crear bucket S3 para tfstate
- [ ] Crear tabla DynamoDB para state locking
- [ ] Configurar permisos IAM para Terraform

### Módulos Terraform
- [ ] Módulo `iam` completo y probado
- [ ] Módulo `dynamodb` completo y probado
- [ ] Módulo `cognito` completo y probado
- [ ] Módulo `lambda` completo y probado
- [ ] Módulo `api-gateway` completo y probado
- [ ] Módulo `s3-cloudfront` completo y probado
- [ ] Módulo `waf` completo y probado
- [ ] Módulo `cloudwatch` completo y probado
- [ ] Módulo `ses` completo y probado

### Ambiente Dev
- [ ] `terraform/environments/dev/main.tf` creado
- [ ] `backend.tf` configurado con S3
- [ ] `terraform.tfvars` con valores dev
- [ ] `terraform init` exitoso
- [ ] `terraform plan` sin errores
- [ ] `terraform apply` exitoso
- [ ] Health checks pasando
- [ ] API funcional
- [ ] Frontend accesible
- [ ] Cognito funcionando
- [ ] Tests E2E pasando

### Ambientes QAS y PRD
- [ ] Ambiente qas configurado
- [ ] Ambiente qas desplegado
- [ ] Tests en qas pasando
- [ ] Ambiente prd configurado
- [ ] Documentación de prd completa

### Limpieza
- [ ] CDK eliminado (después de validación)
- [ ] Build artifacts eliminados
- [ ] Documentación movida a `docs/`
- [ ] Archivos consolidados
- [ ] README actualizado
- [ ] .gitignore actualizado
- [ ] CHANGELOG.md creado

### CI/CD (Opcional)
- [ ] Workflow `terraform-plan.yml`
- [ ] Workflow `terraform-apply-dev.yml`
- [ ] Secrets configurados en GitHub
- [ ] Primera ejecución exitosa

---

## 🎯 Criterios de Éxito

### Técnicos
- ✅ 100% de recursos migraros a Terraform
- ✅ 3 ambientes funcionales (dev, qas, prd)
- ✅ Módulos reutilizables y documentados
- ✅ State management con S3 + DynamoDB
- ✅ Zero downtime durante migración
- ✅ Todos los tests E2E pasando

### Operacionales
- ✅ Deploy de dev < 10 minutos
- ✅ Rollback funcional
- ✅ Documentación actualizada
- ✅ Runbook completo
- ✅ Costos iguales o menores que CDK

### Calidad de Código
- ✅ Módulos siguiendo convenciones Terraform
- ✅ Variables tipadas
- ✅ Outputs documentados
- ✅ Tags consistentes
- ✅ Secrets en variables (no hardcoded)

---

## 📊 Comparativa CDK vs Terraform

| Aspecto | CDK | Terraform |
|---------|-----|-----------|
| **Lenguaje** | JavaScript | HCL |
| **State** | CloudFormation | S3 + DynamoDB |
| **Multi-cloud** | ❌ Solo AWS | ✅ Multi-cloud |
| **Módulos** | Constructs | Modules |
| **Preview** | `cdk diff` | `terraform plan` |
| **Deploy** | `cdk deploy` | `terraform apply` |
| **Import** | Limitado | Robusto |
| **Comunidad** | AWS | HashiCorp + grande |
| **Ambientes** | Manual | Nativo con workspaces |

---

## 💰 Costos Estimados

### Recursos Nuevos (Terraform State)
- **S3 Bucket**: $0.023/GB (~$0.50/mes)
- **DynamoDB Table**: On-demand (~$1/mes)

### Recursos Existentes
- Sin cambios - solo migración de IaC

### Total Adicional
- **~$1.50-2.00/mes** por state management

---

## 🚨 Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Downtime durante migración | Media | Alto | Deploy paralelo, cambio de DNS al final |
| Pérdida de configuración | Baja | Alto | Backup de stacks CDK, export de recursos |
| Costos inesperados | Baja | Medio | `terraform plan` previo, alertas de billing |
| State corruption | Baja | Alto | State locking con DynamoDB, backups de S3 |
| Incompatibilidad de recursos | Media | Medio | Testing exhaustivo en dev primero |

---

## 📞 Soporte

Para dudas sobre la migración:
- 📧 Email: devops@turnaki.com
- 📚 Docs: `/docs/DEPLOYMENT.md`
- 🐛 Issues: GitHub Issues

---

## 📅 Timeline Estimado

```
Semana 1:
├── Día 1-2: Fase 1 (Preparación)
├── Día 3-5: Fase 2 (Módulos Base)

Semana 2:
├── Día 1-3: Fase 3 (Ambiente Dev)
├── Día 4-5: Fase 4 (QAS y PRD)

Semana 3:
├── Día 1-2: Fase 5 (Limpieza)
├── Día 3-4: Fase 6 (CI/CD)
└── Día 5: Validación final y documentación
```

**Total**: 15-18 días hábiles

---

**Documento creado**: 3 de Octubre 2025  
**Última actualización**: 3 de Octubre 2025  
**Versión**: 1.0.0  
**Autor**: Equipo DevOps Turnaki-NexioQ

