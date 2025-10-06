# Módulo DynamoDB - Single-Table Design

## Descripción

Este módulo crea una tabla DynamoDB con diseño single-table, incluyendo dos índices secundarios globales (GSI) para queries eficientes.

## Características

- ✅ Single-table design con PK/SK
- ✅ 2 Global Secondary Indexes (GSI1, GSI2)
- ✅ Modo PAY_PER_REQUEST (on-demand) por defecto
- ✅ Encriptación server-side habilitada
- ✅ Point-in-time recovery opcional
- ✅ Tags configurables

## Diseño de Tabla

### Atributos Principales

| Atributo | Tipo | Uso |
|----------|------|-----|
| `PK` | String | Partition Key (tabla principal) |
| `SK` | String | Sort Key (tabla principal) |
| `GSI1PK` | String | Partition Key (GSI1) |
| `GSI1SK` | String | Sort Key (GSI1) |
| `GSI2PK` | String | Partition Key (GSI2) |
| `GSI2SK` | String | Sort Key (GSI2) |

### Índices

1. **Tabla Principal**: `PK` + `SK`
2. **GSI1**: `GSI1PK` + `GSI1SK` (proyección ALL)
3. **GSI2**: `GSI2PK` + `GSI2SK` (proyección ALL)

## Uso

```hcl
module "dynamodb" {
  source = "../../modules/dynamodb"

  project_name                  = "turnaki-nexioq"
  environment                   = "dev"
  billing_mode                  = "PAY_PER_REQUEST"
  enable_point_in_time_recovery = false

  tags = {
    ManagedBy = "Terraform"
    Module    = "DynamoDB"
  }
}
```

## Variables

| Variable | Tipo | Descripción | Default | Requerido |
|----------|------|-------------|---------|-----------|
| `project_name` | string | Nombre del proyecto | - | ✅ |
| `environment` | string | Ambiente (dev, qas, prd) | - | ✅ |
| `billing_mode` | string | Modo de facturación | `PAY_PER_REQUEST` | ❌ |
| `enable_point_in_time_recovery` | bool | Habilitar PITR | `false` | ❌ |
| `tags` | map(string) | Tags adicionales | `{}` | ❌ |

## Outputs

| Output | Descripción |
|--------|-------------|
| `table_name` | Nombre de la tabla DynamoDB |
| `table_arn` | ARN de la tabla DynamoDB |
| `table_id` | ID de la tabla DynamoDB |

## Patrones de Acceso

### Ejemplo: Turnaki-NexioQ

```hcl
# Tenant
PK: "TENANT#<tenant_id>"
SK: "METADATA"

# Usuario
PK: "TENANT#<tenant_id>"
SK: "USER#<user_id>"
GSI1PK: "USER#<user_id>"
GSI1SK: "TENANT#<tenant_id>"

# Profesional
PK: "TENANT#<tenant_id>"
SK: "PROFESSIONAL#<prof_id>"
GSI1PK: "PROFESSIONAL#<prof_id>"
GSI1SK: "TENANT#<tenant_id>"

# Reserva
PK: "TENANT#<tenant_id>"
SK: "BOOKING#<booking_id>"
GSI1PK: "PROFESSIONAL#<prof_id>"
GSI1SK: "DATE#<date>"
GSI2PK: "USER#<user_id>"
GSI2SK: "DATE#<date>"

# Disponibilidad
PK: "TENANT#<tenant_id>"
SK: "AVAILABILITY#<prof_id>#<date>"
GSI1PK: "AVAILABILITY#<date>"
GSI1SK: "PROFESSIONAL#<prof_id>"
```

## Queries Soportadas

1. **Obtener todos los datos de un tenant**: Query por PK
2. **Obtener reservas de un profesional por fecha**: Query GSI1 
3. **Obtener reservas de un usuario por fecha**: Query GSI2
4. **Obtener disponibilidad por fecha**: Query GSI1

## Ejemplo Completo

```hcl
module "database" {
  source = "../../modules/dynamodb"

  project_name                  = "turnaki-nexioq"
  environment                   = "prd"
  billing_mode                  = "PAY_PER_REQUEST"
  enable_point_in_time_recovery = true  # Activar en PRD

  tags = {
    Environment = "Production"
    CriticalData = "Yes"
    ManagedBy    = "Terraform"
  }
}

# Usar en Lambda
resource "aws_lambda_function" "bookings" {
  # ... otras configuraciones
  
  environment {
    variables = {
      TABLE_NAME = module.database.table_name
    }
  }
}
```

## Convenciones de Nombres

La tabla se nombra siguiendo el patrón:
```
{project_name}-{environment}-main
```

**Ejemplo**: `turnaki-nexioq-dev-main`

## Costos Estimados

### PAY_PER_REQUEST (dev/qas)
- **Lectura**: $0.25 por millón de requests
- **Escritura**: $1.25 por millón de requests
- **Almacenamiento**: $0.25 por GB/mes

### Ejemplo: 10K requests/día
- ~$0.05/día = ~$1.50/mes

## Notas de Seguridad

- ✅ Encriptación at-rest habilitada automáticamente
- ✅ Acceso solo por IAM (no keys/passwords)
- ✅ Point-in-time recovery en PRD
- ⚠️ No hay TTL configurado (agregar si es necesario)

## Requisitos

- Terraform >= 1.0
- AWS Provider >= 5.0

## Mantenimiento

Actualizado: Octubre 2025  
Versión: 1.0.0