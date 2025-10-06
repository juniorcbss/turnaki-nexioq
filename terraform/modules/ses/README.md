# Módulo SES - Simple Email Service

## Descripción

Este módulo configura AWS SES para envío de emails transaccionales con verificación de identidades (email o dominio), DKIM y configuration set para tracking.

## Características

- ✅ Verificación de email individual
- ✅ Verificación de dominio con DKIM
- ✅ Configuration Set para tracking
- ✅ Event tracking en CloudWatch
- ✅ Soporte para múltiples identidades
- ✅ Fácil integración con Lambda

## Uso

### Opción 1: Email Individual (Dev/QAS)

```hcl
module "ses" {
  source = "../../modules/ses"

  project_name   = "turnaki-nexioq"
  environment    = "dev"
  email_identity = "noreply@turnaki.com"

  tags = {
    ManagedBy = "Terraform"
    Module    = "SES"
  }
}
```

### Opción 2: Dominio Completo (PRD)

```hcl
module "ses" {
  source = "../../modules/ses"

  project_name    = "turnaki-nexioq"
  environment     = "prd"
  domain_identity = "turnaki.com"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Variables

| Variable | Tipo | Descripción | Default | Requerido |
|----------|------|-------------|---------|-----------|
| `project_name` | string | Nombre del proyecto | - | ✅ |
| `environment` | string | Ambiente (dev, qas, prd) | - | ✅ |
| `email_identity` | string | Email para verificar | `null` | ❌* |
| `domain_identity` | string | Dominio para verificar | `null` | ❌* |
| `tags` | map(string) | Tags adicionales | `{}` | ❌ |

**\* Al menos uno debe estar definido**: `email_identity` o `domain_identity`

## Outputs

| Output | Descripción |
|--------|-------------|
| `email_identity_arn` | ARN de la identidad email |
| `domain_identity_arn` | ARN de la identidad dominio |
| `dkim_tokens` | Tokens DKIM para DNS |
| `configuration_set_name` | Nombre del configuration set |

## Verificación de Email

### Proceso

1. Terraform crea la identidad
2. AWS envía email de verificación
3. Hacer clic en enlace de verificación
4. Email verificado ✅

### Verificar Status

```bash
aws ses get-identity-verification-attributes \
  --identities noreply@turnaki.com \
  --region us-east-1

# Output
{
  "VerificationAttributes": {
    "noreply@turnaki.com": {
      "VerificationStatus": "Success"  # o "Pending"
    }
  }
}
```

### Reenviar Email de Verificación

```bash
aws ses verify-email-identity \
  --email-address noreply@turnaki.com \
  --region us-east-1
```

## Verificación de Dominio con DKIM

### 1. Crear Módulo

```hcl
module "ses" {
  source = "../../modules/ses"

  project_name    = "turnaki-nexioq"
  environment     = "prd"
  domain_identity = "turnaki.com"
}
```

### 2. Obtener Tokens DKIM

```bash
terraform output -json ses_dkim_tokens

# Output
[
  "token1abc123",
  "token2def456",
  "token3ghi789"
]
```

### 3. Configurar DNS

Agregar estos registros CNAME en tu DNS:

```
# Registro TXT para verificación de dominio
_amazonses.turnaki.com    TXT    "verification_token_from_aws"

# Registros CNAME para DKIM (3 registros)
token1abc123._domainkey.turnaki.com    CNAME    token1abc123.dkim.amazonses.com
token2def456._domainkey.turnaki.com    CNAME    token2def456.dkim.amazonses.com
token3ghi789._domainkey.turnaki.com    CNAME    token3ghi789.dkim.amazonses.com
```

### 4. Verificar DNS

```bash
# Verificar dominio
dig TXT _amazonses.turnaki.com

# Verificar DKIM
dig CNAME token1abc123._domainkey.turnaki.com
```

## Ejemplo con Route53

```hcl
module "ses" {
  source = "../../modules/ses"

  project_name    = "turnaki-nexioq"
  environment     = "prd"
  domain_identity = "turnaki.com"
}

# Obtener zona DNS
data "aws_route53_zone" "main" {
  name = "turnaki.com"
}

# Registros DKIM automáticos
resource "aws_route53_record" "ses_dkim" {
  count = 3

  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${module.ses.dkim_tokens[count.index]}._domainkey.turnaki.com"
  type    = "CNAME"
  ttl     = 600
  records = ["${module.ses.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# Registro de verificación
resource "aws_route53_record" "ses_verification" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_amazonses.turnaki.com"
  type    = "TXT"
  ttl     = 600
  records = [module.ses.verification_token]
}
```

## Configuration Set

### Eventos Trackeados

El módulo trackea estos eventos automáticamente:

- ✅ **Send**: Email enviado exitosamente
- ✅ **Reject**: Email rechazado (bounce antes de envío)
- ✅ **Bounce**: Email rebotado por servidor destino
- ✅ **Complaint**: Marcado como spam
- ✅ **Delivery**: Email entregado exitosamente

### Ver Métricas

```bash
# CloudWatch Metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/SES \
  --metric-name Send \
  --dimensions Name=ConfigurationSet,Value=turnaki-nexioq-prd-emails \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

## Envío de Emails desde Lambda

### Rust

```rust
use aws_sdk_ses::{Client, model::*};

async fn send_email(
    client: &Client,
    to: &str,
    subject: &str,
    body: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    let result = client
        .send_email()
        .source("noreply@turnaki.com")
        .destination(
            Destination::builder()
                .to_addresses(to)
                .build()
        )
        .message(
            Message::builder()
                .subject(Content::builder().data(subject).build())
                .body(
                    Body::builder()
                        .html(Content::builder().data(body).build())
                        .build()
                )
                .build()
        )
        .configuration_set_name("turnaki-nexioq-prd-emails")
        .send()
        .await?;

    Ok(result.message_id().unwrap().to_string())
}
```

### Permisos IAM

```hcl
# En módulo IAM, habilitar SES
module "notification_lambda_role" {
  source = "../../modules/iam"

  project_name       = "turnaki-nexioq"
  environment        = "prd"
  function_name      = "send-notification"
  enable_ses_access  = true  # ✅ Importante
}
```

## Ejemplo Completo

```hcl
# 1. SES con dominio
module "ses" {
  source = "../../modules/ses"

  project_name    = "turnaki-nexioq"
  environment     = "prd"
  domain_identity = "turnaki.com"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# 2. DNS con Route53
data "aws_route53_zone" "main" {
  name = "turnaki.com"
}

resource "aws_route53_record" "ses_dkim" {
  count = 3

  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${module.ses.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = 600
  records = ["${module.ses.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# 3. Lambda para envío
module "notification_role" {
  source = "../../modules/iam"

  project_name       = "turnaki-nexioq"
  environment        = "prd"
  function_name      = "send-notification"
  enable_ses_access  = true
}

module "notification_lambda" {
  source = "../../modules/lambda"

  project_name         = "turnaki-nexioq"
  environment          = "prd"
  function_name        = "send-notification"
  iam_role_arn         = module.notification_role.role_arn
  lambda_zip_path      = "../../../backend/target/lambda/send-notification/bootstrap.zip"
  dynamodb_table_name  = module.dynamodb.table_name
  
  environment_variables = {
    SES_FROM_EMAIL        = "noreply@turnaki.com"
    SES_CONFIGURATION_SET = module.ses.configuration_set_name
  }
}

# 4. CloudWatch Alarma para bounces
resource "aws_cloudwatch_metric_alarm" "ses_bounce" {
  alarm_name          = "${var.project_name}-${var.environment}-ses-bounce-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Reputation.BounceRate"
  namespace           = "AWS/SES"
  period              = "900"
  statistic           = "Average"
  threshold           = "0.05"  # 5%
  alarm_description   = "SES bounce rate exceeded 5%"
  
  dimensions = {
    ConfigurationSet = module.ses.configuration_set_name
  }
}
```

## Sandbox vs Production

### Sandbox (Default)

- ✅ Solo emails verificados
- ✅ Máximo 200 emails/día
- ✅ 1 email/segundo
- ❌ No puede enviar a usuarios reales

### Salir del Sandbox (Production)

```bash
# 1. Abrir caso en AWS Support
# AWS Console → Support → Create Case
# Type: Service Limit Increase
# Limit Type: SES Sending Limits

# 2. Completar formulario:
# - Use case description
# - Website URL
# - Email compliance plan
# - Bounce/complaint handling

# 3. Esperar aprobación (24-48 horas)
```

### Production Limits

- ✅ Emails ilimitados
- ✅ 50,000 emails/día (inicial, aumentable)
- ✅ 14 emails/segundo (inicial)
- ✅ Envío a cualquier email

## Monitoreo de Reputación

### Métricas Clave

| Métrica | Umbral Seguro | Acción si Excede |
|---------|---------------|------------------|
| Bounce Rate | < 5% | Limpiar lista emails |
| Complaint Rate | < 0.1% | Revisar contenido |
| Delivery Rate | > 95% | Verificar DNS/DKIM |

### Dashboard

```bash
# AWS Console
SES → Reputation Metrics

# Muestra:
- Bounce rate (últimos 15 min)
- Complaint rate
- Sending quota
- Sending rate
```

## Templates HTML

### Crear Template

```hcl
resource "aws_ses_template" "booking_confirmation" {
  name    = "booking-confirmation"
  subject = "Confirmación de Reserva - {{booking_id}}"
  
  html = file("${path.module}/templates/booking-confirmation.html")
  text = "Tu reserva {{booking_id}} ha sido confirmada."
}
```

### Usar Template

```rust
client
    .send_templated_email()
    .source("noreply@turnaki.com")
    .destination(Destination::builder().to_addresses(user_email).build())
    .template("booking-confirmation")
    .template_data(r#"{"booking_id": "BK-123", "date": "2025-10-15"}"#)
    .send()
    .await?;
```

## Convenciones de Nombres

```
Configuration Set: {project_name}-{environment}-emails
Template: {template-name} (kebab-case)
```

**Ejemplos**:
- Configuration Set: `turnaki-nexioq-prd-emails`
- Template: `booking-confirmation`

## Costos Estimados

### Pricing

- **Email enviado**: $0.10 por 1,000 emails
- **Emails recibidos**: $0.09 por 1,000 emails
- **Sin costo fijo mensual**

### Ejemplo: 100,000 emails/mes

```
Envío: 100,000 × $0.10/1K = $10.00
Total: $10.00/mes
```

## Notas de Seguridad

- ✅ DKIM firmado automáticamente
- ✅ SPF (configurar en DNS)
- ✅ DMARC recomendado para PRD
- ✅ Rate limiting automático
- ⚠️ No enviar emails no solicitados (spam)
- ⚠️ Mantener bounce rate < 5%

## Troubleshooting

### Email no llega

```
1. Verificar identidad verificada
2. Verificar DKIM configurado
3. Revisar bounce rate
4. Verificar sandbox/production
```

### Bounce rate alto

```
1. Limpiar lista de emails
2. Verificar formato de emails
3. Implementar double opt-in
4. Remover emails inválidos
```

### Complaint rate alto

```
1. Revisar contenido emails
2. Agregar unsubscribe link
3. No comprar listas de emails
4. Verificar frecuencia de envío
```

## Requisitos

- Terraform >= 1.0
- AWS Provider >= 5.0
- Acceso a DNS del dominio (para DKIM)

## Mantenimiento

Actualizado: Octubre 2025  
Versión: 1.0.0