# Módulo WAF - Web Application Firewall

## Descripción

Este módulo crea un AWS WAFv2 Web ACL con protección contra ataques comunes, rate limiting y reglas administradas por AWS.

## Características

- ✅ Rate limiting por IP
- ✅ AWS Managed Rules - Core Rule Set
- ✅ AWS Managed Rules - Known Bad Inputs
- ✅ Métricas en CloudWatch
- ✅ Sample requests habilitado
- ✅ Scope configurable (REGIONAL/CLOUDFRONT)
- ✅ Acción por defecto: ALLOW

## Uso

```hcl
module "waf" {
  source = "../../modules/waf"

  project_name = "turnaki-nexioq"
  environment  = "dev"
  scope        = "REGIONAL"
  rate_limit   = 2000

  tags = {
    ManagedBy = "Terraform"
    Module    = "WAF"
  }
}

# Asociar con API Gateway
resource "aws_wafv2_web_acl_association" "api" {
  resource_arn = module.api_gateway.api_arn
  web_acl_arn  = module.waf.web_acl_arn
}
```

## Variables

| Variable | Tipo | Descripción | Default | Requerido |
|----------|------|-------------|---------|-----------|
| `project_name` | string | Nombre del proyecto | - | ✅ |
| `environment` | string | Ambiente (dev, qas, prd) | - | ✅ |
| `scope` | string | Scope del WAF | `REGIONAL` | ❌ |
| `rate_limit` | number | Límite de requests/5min | `2000` | ❌ |
| `tags` | map(string) | Tags adicionales | `{}` | ❌ |

## Outputs

| Output | Descripción |
|--------|-------------|
| `web_acl_id` | ID del Web ACL |
| `web_acl_arn` | ARN del Web ACL |
| `web_acl_capacity` | Capacidad WCU utilizada |

## Scope

### REGIONAL
- API Gateway (Regional)
- Application Load Balancer
- App Runner
- Cognito User Pool

### CLOUDFRONT
- CloudFront Distributions
- **Debe crearse en us-east-1**

## Reglas Incluidas

### 1. Rate Limiting (Prioridad 1)

**Propósito**: Prevenir DDoS y abuso

```
Límite: 2000 requests por 5 minutos por IP
Acción: BLOCK
Métrica: {project}-{env}-rate-limit
```

**Ejemplo**: 
- IP hace 2001 requests en 5 min → Bloqueado
- IP hace 1999 requests → Permitido

### 2. AWS Managed Rules - Core Rule Set (Prioridad 2)

**Propósito**: Protección OWASP Top 10

Incluye protección contra:
- ✅ SQL Injection
- ✅ XSS (Cross-Site Scripting)
- ✅ Local File Inclusion (LFI)
- ✅ Remote File Inclusion (RFI)
- ✅ PHP Injection
- ✅ Cross-Site Request Forgery (CSRF)

### 3. AWS Managed Rules - Known Bad Inputs (Prioridad 3)

**Propósito**: Bloquear inputs maliciosos conocidos

Incluye:
- ✅ Log4j vulnerabilities (Log4Shell)
- ✅ Shellshock
- ✅ Malformed requests
- ✅ Known attack patterns

## Métricas CloudWatch

### Métricas Disponibles

```
- AllowedRequests
- BlockedRequests
- CountedRequests
- SampledRequests
```

### Consultar Métricas

```bash
# Requests bloqueados (últimas 24h)
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=Rule,Value=turnaki-nexioq-dev-rate-limit \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

## Ejemplo Completo

```hcl
# 1. WAF para API Gateway
module "waf_api" {
  source = "../../modules/waf"

  project_name = "turnaki-nexioq"
  environment  = "prd"
  scope        = "REGIONAL"
  rate_limit   = 5000  # Más alto en PRD

  tags = {
    Environment = "Production"
    Resource    = "API-Gateway"
    ManagedBy   = "Terraform"
  }
}

resource "aws_wafv2_web_acl_association" "api" {
  resource_arn = module.api_gateway.api_arn
  web_acl_arn  = module.waf_api.web_acl_arn
}

# 2. WAF para CloudFront (debe estar en us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "waf_cloudfront" {
  source = "../../modules/waf"
  
  providers = {
    aws = aws.us_east_1
  }

  project_name = "turnaki-nexioq"
  environment  = "prd"
  scope        = "CLOUDFRONT"
  rate_limit   = 10000

  tags = {
    Environment = "Production"
    Resource    = "CloudFront"
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudfront_distribution" "frontend" {
  # ... otras configuraciones
  
  web_acl_id = module.waf_cloudfront.web_acl_arn
}

# 3. Alarma CloudWatch
resource "aws_cloudwatch_metric_alarm" "waf_blocked" {
  alarm_name          = "waf-blocked-requests-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "WAF blocking high number of requests"
  
  dimensions = {
    Rule   = "${var.project_name}-${var.environment}-rate-limit"
    Region = var.region
  }
}
```

## Rate Limiting Recomendado

| Ambiente | Rate Limit | Uso |
|----------|------------|-----|
| Dev | 2000/5min | Testing |
| QAS | 3000/5min | Pre-producción |
| PRD | 5000-10000/5min | Producción |

### Cálculo

```
Rate Limit = Usuarios Concurrentes × Requests/Min × 5
```

**Ejemplo**: 100 usuarios, 5 req/min → 100 × 5 × 5 = 2500

## Logs y Sampled Requests

### Ver Sampled Requests

```bash
# AWS Console
WAF & Shield → Web ACLs → {acl-name} → Sampled requests

# Muestra:
- Requests bloqueados
- IP origen
- Header values
- Body (si aplicable)
```

### Habilitar Logging (Opcional)

```hcl
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  resource_arn = module.waf.web_acl_arn
  
  log_destination_configs = [
    aws_kinesis_firehose_delivery_stream.waf_logs.arn
  ]

  redacted_fields {
    single_header {
      name = "authorization"  # Redactar tokens
    }
  }
}

resource "aws_s3_bucket" "waf_logs" {
  bucket = "turnaki-nexioq-prd-waf-logs"
}

resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  name        = "aws-waf-logs-turnaki-nexioq-prd"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.waf_logs.arn
    prefix     = "waf/"
  }
}
```

## Capacidad WCU

### Web ACL Capacity Units

Cada regla consume WCUs:

| Regla | WCU |
|-------|-----|
| Rate Limiting | 2 |
| Core Rule Set | 700 |
| Known Bad Inputs | 200 |
| **Total** | **902** |

**Límite máximo**: 5000 WCU

## Falsos Positivos

### Excluir Reglas Específicas

```hcl
# Excluir regla específica que causa falsos positivos
rule {
  name     = "AWSManagedRulesCommonRuleSet"
  priority = 2

  override_action {
    none {}
  }

  statement {
    managed_rule_group_statement {
      name        = "AWSManagedRulesCommonRuleSet"
      vendor_name = "AWS"

      # Excluir regla específica
      rule_action_override {
        action_to_use {
          count {}  # Count en lugar de Block
        }
        name = "SizeRestrictions_BODY"
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-common-rules"
    sampled_requests_enabled   = true
  }
}
```

## Convenciones de Nombres

```
Web ACL: {project_name}-{environment}-waf
Metrics: {project_name}-{environment}-{rule-name}
```

**Ejemplos**:
- Web ACL: `turnaki-nexioq-dev-waf`
- Metric: `turnaki-nexioq-dev-rate-limit`

## Costos Estimados

### Pricing

- **Web ACL**: $5.00/mes
- **Regla básica**: $1.00/mes
- **Managed Rule Group**: $10.00/mes
- **Requests**: $0.60/1M requests

### Ejemplo: 3 reglas (1 básica + 2 managed), 10M requests/mes

```
Web ACL:        $5.00
Regla básica:   $1.00 × 1 = $1.00
Managed rules:  $10.00 × 2 = $20.00
Requests:       10M × $0.60/1M = $6.00
Total: $32.00/mes
```

## Notas de Seguridad

- ✅ Managed rules actualizadas automáticamente por AWS
- ✅ Rate limiting previene DDoS
- ✅ Métricas y logs para auditoría
- ⚠️ Revisar sampled requests semanalmente
- ⚠️ Ajustar rate limit según carga real

## Requisitos

- Terraform >= 1.0
- AWS Provider >= 5.0
- Scope CLOUDFRONT requiere us-east-1

## Mantenimiento

Actualizado: Octubre 2025  
Versión: 1.0.0