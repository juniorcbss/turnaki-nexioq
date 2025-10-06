# Módulo IAM - Roles y Políticas para Lambda

## Descripción

Este módulo crea roles IAM reutilizables para funciones Lambda con políticas básicas y opcionales para DynamoDB y SES.

## Características

- ✅ Rol IAM con política de asunción para Lambda
- ✅ Política básica de ejecución Lambda (CloudWatch Logs)
- ✅ Integración con AWS X-Ray para tracing
- ✅ Política opcional para acceso a DynamoDB (lectura/escritura)
- ✅ Política opcional para envío de emails con SES
- ✅ Tags configurables

## Uso

```hcl
module "lambda_role" {
  source = "../../modules/iam"

  project_name         = "turnaki-nexioq"
  environment          = "dev"
  function_name        = "bookings"
  dynamodb_table_arn   = aws_dynamodb_table.main.arn
  enable_ses_access    = true

  tags = {
    ManagedBy = "Terraform"
    Module    = "IAM"
  }
}
```

## Variables

| Variable | Tipo | Descripción | Default | Requerido |
|----------|------|-------------|---------|-----------|
| `project_name` | string | Nombre del proyecto | - | ✅ |
| `environment` | string | Ambiente (dev, qas, prd) | - | ✅ |
| `function_name` | string | Nombre de la función Lambda | - | ✅ |
| `dynamodb_table_arn` | string | ARN de la tabla DynamoDB | `null` | ❌ |
| `enable_ses_access` | bool | Habilitar acceso a SES | `false` | ❌ |
| `tags` | map(string) | Tags adicionales | `{}` | ❌ |

## Outputs

| Output | Descripción |
|--------|-------------|
| `role_arn` | ARN del rol IAM creado |
| `role_name` | Nombre del rol IAM creado |

## Políticas Incluidas

### Básicas (Siempre)
- `AWSLambdaBasicExecutionRole` - Logs en CloudWatch
- `AWSXRayDaemonWriteAccess` - Tracing con X-Ray

### Opcionales
- **DynamoDB** (si `dynamodb_table_arn` está definido):
  - GetItem, PutItem, UpdateItem, DeleteItem
  - Query, Scan
  - Acceso a índices GSI

- **SES** (si `enable_ses_access = true`):
  - SendEmail, SendRawEmail

## Ejemplo Completo

```hcl
# Crear tabla DynamoDB primero
resource "aws_dynamodb_table" "main" {
  name         = "turnaki-nexioq-dev-main"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"
  # ... más configuración
}

# Crear rol IAM para Lambda con acceso completo
module "bookings_role" {
  source = "../../modules/iam"

  project_name         = "turnaki-nexioq"
  environment          = "dev"
  function_name        = "bookings"
  dynamodb_table_arn   = aws_dynamodb_table.main.arn
  enable_ses_access    = false

  tags = {
    Function  = "Bookings"
    ManagedBy = "Terraform"
  }
}

# Usar el rol en una Lambda
module "bookings_lambda" {
  source = "../../modules/lambda"

  # ... otras variables
  iam_role_arn = module.bookings_role.role_arn
}
```

## Convenciones de Nombres

El rol se nombra siguiendo el patrón:
```
{project_name}-{environment}-lambda-{function_name}
```

**Ejemplo**: `turnaki-nexioq-dev-lambda-bookings`

## Notas de Seguridad

- ✅ Principio de mínimo privilegio
- ✅ Las políticas de DynamoDB solo se crean si es necesario
- ✅ Las políticas de SES solo se crean si es necesario
- ⚠️ SES tiene permisos a `Resource: "*"` (limitación de AWS)

## Requisitos

- Terraform >= 1.0
- AWS Provider >= 5.0

## Mantenimiento

Actualizado: Octubre 2025  
Versión: 1.0.0