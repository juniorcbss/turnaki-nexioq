# Módulo Lambda - Función Genérica para Rust

## Descripción

Este módulo crea una función AWS Lambda optimizada para binarios Rust con arquitectura ARM64, incluyendo CloudWatch Logs, X-Ray tracing y permisos opcionales para API Gateway.

## Características

- ✅ Runtime custom para Rust (provided.al2023)
- ✅ Arquitectura ARM64 (mejor costo-rendimiento)
- ✅ CloudWatch Logs con retención configurable
- ✅ X-Ray tracing activado
- ✅ Variables de entorno predefinidas y personalizables
- ✅ Permiso opcional para API Gateway
- ✅ Actualizaciones automáticas con source_code_hash

## Uso

```hcl
module "bookings_lambda" {
  source = "../../modules/lambda"

  project_name         = "turnaki-nexioq"
  environment          = "dev"
  function_name        = "bookings"
  iam_role_arn         = module.bookings_role.role_arn
  lambda_zip_path      = "../../../backend/target/lambda/bookings/bootstrap.zip"
  dynamodb_table_name  = module.dynamodb.table_name
  
  timeout     = 30
  memory_size = 512
  log_level   = "info"
  
  environment_variables = {
    CUSTOM_VAR = "value"
  }

  api_gateway_arn    = module.api_gateway.api_execution_arn
  log_retention_days = 7

  tags = {
    Function  = "Bookings"
    ManagedBy = "Terraform"
  }
}
```

## Variables

| Variable | Tipo | Descripción | Default | Requerido |
|----------|------|-------------|---------|-----------|
| `project_name` | string | Nombre del proyecto | - | ✅ |
| `environment` | string | Ambiente (dev, qas, prd) | - | ✅ |
| `function_name` | string | Nombre de la función | - | ✅ |
| `iam_role_arn` | string | ARN del rol IAM | - | ✅ |
| `lambda_zip_path` | string | Ruta al archivo ZIP | - | ✅ |
| `dynamodb_table_name` | string | Nombre de la tabla DynamoDB | - | ✅ |
| `timeout` | number | Timeout en segundos | `30` | ❌ |
| `memory_size` | number | Memoria en MB | `512` | ❌ |
| `log_level` | string | Nivel de log | `info` | ❌ |
| `environment_variables` | map(string) | Variables adicionales | `{}` | ❌ |
| `api_gateway_arn` | string | ARN del API Gateway | `null` | ❌ |
| `log_retention_days` | number | Retención de logs | `7` | ❌ |
| `tags` | map(string) | Tags adicionales | `{}` | ❌ |

## Outputs

| Output | Descripción |
|--------|-------------|
| `function_arn` | ARN de la función Lambda |
| `function_name` | Nombre de la función |
| `function_invoke_arn` | ARN de invocación |
| `log_group_name` | Nombre del Log Group |

## Variables de Entorno Predefinidas

Estas variables se inyectan automáticamente:

```hcl
RUST_LOG   = var.log_level    # "info", "debug", "error"
LOG_LEVEL  = var.log_level    # Mismo valor
TABLE_NAME = var.dynamodb_table_name
```

Variables adicionales se pueden agregar con `environment_variables`.

## Compilación del Binario Rust

### Prerrequisitos

```bash
# Instalar Cargo Lambda
brew install cargo-lambda
# o
cargo install cargo-lambda
```

### Build para Lambda

```bash
cd backend

# Build ARM64 optimizado
cargo lambda build --arm64 --release --function bookings

# El ZIP se genera en:
# backend/target/lambda/bookings/bootstrap.zip
```

### Estructura del ZIP

```
bootstrap.zip
└── bootstrap  # Binario Rust compilado
```

## Configuración de Memoria y Timeout

### Recomendaciones

| Tipo de Función | Memory (MB) | Timeout (s) |
|----------------|-------------|-------------|
| API simple (CRUD) | 256-512 | 10-30 |
| Procesamiento medio | 512-1024 | 30-60 |
| Procesamiento pesado | 1024-3008 | 60-300 |
| Async/Background | 512-1024 | 300-900 |

### ARM64 vs x86_64

ARM64 ofrece:
- ✅ ~20% mejor costo-rendimiento
- ✅ Mismo rendimiento con menos memoria
- ✅ Menor consumo energético

## Ejemplo Completo

```hcl
# 1. Crear rol IAM
module "bookings_role" {
  source = "../../modules/iam"

  project_name         = "turnaki-nexioq"
  environment          = "dev"
  function_name        = "bookings"
  dynamodb_table_arn   = module.dynamodb.table_arn
  enable_ses_access    = false
}

# 2. Crear Lambda
module "bookings_lambda" {
  source = "../../modules/lambda"

  project_name         = "turnaki-nexioq"
  environment          = "dev"
  function_name        = "bookings"
  iam_role_arn         = module.bookings_role.role_arn
  lambda_zip_path      = "${path.module}/../../../backend/target/lambda/bookings/bootstrap.zip"
  dynamodb_table_name  = module.dynamodb.table_name
  
  timeout     = 30
  memory_size = 512
  log_level   = "info"
  
  environment_variables = {
    COGNITO_USER_POOL_ID = module.cognito.user_pool_id
  }

  api_gateway_arn    = module.api_gateway.api_execution_arn
  log_retention_days = 7

  tags = {
    Function  = "Bookings"
    Runtime   = "Rust"
    ManagedBy = "Terraform"
  }
}

# 3. Crear integración con API Gateway
resource "aws_apigatewayv2_integration" "bookings" {
  api_id           = module.api_gateway.api_id
  integration_type = "AWS_PROXY"

  integration_uri    = module.bookings_lambda.function_invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "bookings_list" {
  api_id    = module.api_gateway.api_id
  route_key = "GET /bookings"
  target    = "integrations/${aws_apigatewayv2_integration.bookings.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api_gateway.authorizer_id
}
```

## Logs y Debugging

### Ver logs en tiempo real

```bash
# CloudWatch Logs Insights
aws logs tail /aws/lambda/turnaki-nexioq-dev-bookings --follow

# O usar AWS Console
# CloudWatch → Log Groups → /aws/lambda/turnaki-nexioq-dev-bookings
```

### X-Ray Tracing

```bash
# Ver traces
aws xray get-trace-summaries --start-time 2025-10-06T00:00:00 --end-time 2025-10-06T23:59:59

# O usar AWS Console
# X-Ray → Service Map
```

## Actualización de Código

Terraform detecta cambios automáticamente mediante `source_code_hash`:

```bash
# 1. Rebuild Rust
cd backend
cargo lambda build --arm64 --release --function bookings

# 2. Redeploy con Terraform
cd ../terraform/environments/dev
terraform apply
```

## Convenciones de Nombres

```
Function: {project_name}-{environment}-{function_name}
Log Group: /aws/lambda/{function_name}
```

**Ejemplos**:
- Función: `turnaki-nexioq-dev-bookings`
- Log Group: `/aws/lambda/turnaki-nexioq-dev-bookings`

## Costos Estimados

### Pricing (ARM64 en us-east-1)

- **Requests**: $0.20 por 1M requests
- **Compute**: $0.0000133334/GB-segundo

### Ejemplo: 512MB, 100ms promedio, 100K requests/mes

```
Requests: 100,000 × $0.20/1M = $0.02
Compute:  100,000 × 0.1s × 0.5GB × $0.0000133334 = $0.07
Total: ~$0.09/mes
```

## Notas de Rendimiento

- ✅ Cold start ~100-300ms (Rust es rápido)
- ✅ Warm execution ~10-50ms
- ✅ ARM64 20% más eficiente que x86
- ⚠️ Provisioned Concurrency para casos críticos (costo extra)

## Requisitos

- Terraform >= 1.0
- AWS Provider >= 5.0
- Cargo Lambda >= 1.0
- Rust >= 1.75

## Mantenimiento

Actualizado: Octubre 2025  
Versión: 1.0.0