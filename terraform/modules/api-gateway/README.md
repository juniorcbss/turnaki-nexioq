# Módulo API Gateway - HTTP API con JWT Authorizer

## Descripción

Este módulo crea un API Gateway HTTP API con JWT Authorizer de Cognito, configuración CORS, throttling y logs estructurados en CloudWatch.

## Características

- ✅ HTTP API (más rápido y económico que REST API)
- ✅ JWT Authorizer con Cognito
- ✅ CORS configurado automáticamente
- ✅ Throttling por defecto
- ✅ Access logs estructurados en JSON
- ✅ Stage $default con auto-deploy
- ✅ Tags configurables

## Uso

```hcl
module "api_gateway" {
  source = "../../modules/api-gateway"

  project_name       = "turnaki-nexioq"
  environment        = "dev"
  cognito_client_id  = module.cognito.client_id
  cognito_issuer     = module.cognito.issuer
  
  cors_allowed_origins = [
    "http://localhost:5173",
    "https://dev.turnaki.nexioq.com"
  ]
  
  throttle_burst_limit = 100
  throttle_rate_limit  = 50
  log_retention_days   = 7

  tags = {
    ManagedBy = "Terraform"
    Module    = "API-Gateway"
  }
}
```

## Variables

| Variable | Tipo | Descripción | Default | Requerido |
|----------|------|-------------|---------|-----------|
| `project_name` | string | Nombre del proyecto | - | ✅ |
| `environment` | string | Ambiente (dev, qas, prd) | - | ✅ |
| `cognito_client_id` | string | ID del Cognito Client | - | ✅ |
| `cognito_issuer` | string | URL del issuer Cognito | - | ✅ |
| `cors_allowed_origins` | list(string) | Orígenes permitidos CORS | - | ✅ |
| `throttle_burst_limit` | number | Límite de ráfaga | `100` | ❌ |
| `throttle_rate_limit` | number | Límite de tasa | `50` | ❌ |
| `log_retention_days` | number | Retención de logs | `7` | ❌ |
| `tags` | map(string) | Tags adicionales | `{}` | ❌ |

## Outputs

| Output | Descripción |
|--------|-------------|
| `api_id` | ID del API Gateway |
| `api_endpoint` | URL del API Gateway |
| `api_execution_arn` | ARN de ejecución |
| `authorizer_id` | ID del JWT Authorizer |
| `stage_id` | ID del Stage |

## Configuración CORS

### Headers Permitidos
- `authorization`
- `content-type`
- `x-amz-date`
- `x-api-key`

### Métodos Permitidos
- `GET`
- `POST`
- `PUT`
- `PATCH`
- `DELETE`
- `OPTIONS`

### Max Age
- `3600` segundos (1 hora)

## JWT Authorizer

### Configuración

```hcl
Identity Source: Authorization header
Token Type: JWT
Audience: [cognito_client_id]
Issuer: https://cognito-idp.{region}.amazonaws.com/{user_pool_id}
```

### Validación Automática

- ✅ Firma del token
- ✅ Expiración (exp claim)
- ✅ Issuer correcto
- ✅ Audience correcto

## Throttling

### Límites Configurables

| Parámetro | Descripción | Default |
|-----------|-------------|---------|
| `burst_limit` | Requests simultáneos máximos | 100 |
| `rate_limit` | Requests por segundo | 50 |

### Comportamiento

- Requests > burst_limit → **429 Too Many Requests**
- Promedio > rate_limit → **429 Too Many Requests**

## Access Logs

### Formato JSON

```json
{
  "requestId": "$context.requestId",
  "ip": "$context.identity.sourceIp",
  "requestTime": "$context.requestTime",
  "httpMethod": "$context.httpMethod",
  "routeKey": "$context.routeKey",
  "status": "$context.status",
  "protocol": "$context.protocol",
  "responseLength": "$context.responseLength"
}
```

### Consultar Logs

```bash
# CloudWatch Logs Insights
aws logs tail /aws/apigateway/turnaki-nexioq-dev-api --follow

# Query: Errores 5XX
fields @timestamp, status, routeKey, ip
| filter status >= 500
| sort @timestamp desc
```

## Ejemplo Completo

```hcl
# 1. Crear Cognito
module "cognito" {
  source = "../../modules/cognito"
  # ... configuración
}

# 2. Crear API Gateway
module "api" {
  source = "../../modules/api-gateway"

  project_name       = "turnaki-nexioq"
  environment        = "prd"
  cognito_client_id  = module.cognito.client_id
  cognito_issuer     = module.cognito.issuer
  
  cors_allowed_origins = [
    "https://turnaki.nexioq.com",
    "https://app.turnaki.nexioq.com"
  ]
  
  throttle_burst_limit = 200  # Más alto en PRD
  throttle_rate_limit  = 100
  log_retention_days   = 30   # Más largo en PRD

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# 3. Crear Lambda
module "bookings_lambda" {
  source = "../../modules/lambda"
  # ... configuración
  api_gateway_arn = module.api.api_execution_arn
}

# 4. Crear integración
resource "aws_apigatewayv2_integration" "bookings" {
  api_id           = module.api.api_id
  integration_type = "AWS_PROXY"
  integration_uri  = module.bookings_lambda.function_invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# 5. Crear rutas
resource "aws_apigatewayv2_route" "get_bookings" {
  api_id    = module.api.api_id
  route_key = "GET /bookings"
  target    = "integrations/${aws_apigatewayv2_integration.bookings.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api.authorizer_id
}

resource "aws_apigatewayv2_route" "post_bookings" {
  api_id    = module.api.api_id
  route_key = "POST /bookings"
  target    = "integrations/${aws_apigatewayv2_integration.bookings.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api.authorizer_id
}

# 6. Ruta pública (sin auth)
resource "aws_apigatewayv2_route" "health" {
  api_id    = module.api.api_id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.health.id}"
  
  authorization_type = "NONE"  # Pública
}
```

## Rutas y Autenticación

### Ruta Protegida (con JWT)

```typescript
// Frontend
const response = await fetch(`${apiEndpoint}/bookings`, {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json'
  }
});
```

### Ruta Pública (sin JWT)

```typescript
const response = await fetch(`${apiEndpoint}/health`, {
  method: 'GET'
});
```

## Convenciones de Nombres

```
API: {project_name}-{environment}-api
Log Group: /aws/apigateway/{project_name}-{environment}-api
Stage: $default (siempre)
```

**Ejemplos**:
- API: `turnaki-nexioq-dev-api`
- Log Group: `/aws/apigateway/turnaki-nexioq-dev-api`

## Costos Estimados

### HTTP API Pricing

- **Requests**: $1.00 por millón de requests
- **Sin costo por hora/mes**

### Ejemplo: 1M requests/mes

```
Requests: 1,000,000 × $1.00/1M = $1.00
Total: $1.00/mes
```

### Comparación REST vs HTTP API

| Feature | REST API | HTTP API |
|---------|----------|----------|
| Precio | $3.50/M | $1.00/M |
| Latencia | ~50ms | ~20ms |
| JWT Auth | ❌ (usar Lambda) | ✅ Nativo |

## Notas de Rendimiento

- ✅ Latencia típica: 20-30ms
- ✅ Auto-scaling automático
- ✅ Regional (baja latencia en región)
- ⚠️ Usar CloudFront para distribución global

## Seguridad

- ✅ HTTPS obligatorio
- ✅ JWT validation automática
- ✅ Throttling habilitado
- ✅ CORS restrictivo
- ⚠️ Combinar con WAF en PRD
- ⚠️ API Keys para clientes externos

## Troubleshooting

### Error 401 Unauthorized

```
- Verificar que el token no haya expirado
- Verificar que el issuer sea correcto
- Verificar que el client_id esté en audience
```

### Error 429 Too Many Requests

```
- Aumentar throttle_burst_limit
- Aumentar throttle_rate_limit
- Implementar retry con exponential backoff
```

### Error 500 Internal Server Error

```
- Revisar logs de Lambda
- Verificar permisos de invocación
- Verificar formato de respuesta Lambda
```

## Requisitos

- Terraform >= 1.0
- AWS Provider >= 5.0
- Cognito User Pool configurado

## Mantenimiento

Actualizado: Octubre 2025  
Versión: 1.0.0