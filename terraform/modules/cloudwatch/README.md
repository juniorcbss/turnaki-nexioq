# Módulo CloudWatch - Observabilidad y Alarmas

## Descripción

Este módulo crea un dashboard de CloudWatch con métricas clave, SNS topic para notificaciones y alarmas configurables para Lambda y API Gateway.

## Características

- ✅ Dashboard con métricas de Lambda, API Gateway y DynamoDB
- ✅ SNS Topic para notificaciones
- ✅ Suscripción por email opcional
- ✅ Alarmas configurables
- ✅ Métricas en tiempo real
- ✅ Widgets personalizables

## Uso

```hcl
module "monitoring" {
  source = "../../modules/cloudwatch"

  project_name = "turnaki-nexioq"
  environment  = "dev"
  region       = "us-east-1"
  
  enable_alarms           = true
  alarm_email             = "devops@turnaki.com"
  lambda_error_threshold  = 10
  api_5xx_threshold       = 10

  tags = {
    ManagedBy = "Terraform"
    Module    = "CloudWatch"
  }
}
```

## Variables

| Variable | Tipo | Descripción | Default | Requerido |
|----------|------|-------------|---------|-----------|
| `project_name` | string | Nombre del proyecto | - | ✅ |
| `environment` | string | Ambiente (dev, qas, prd) | - | ✅ |
| `region` | string | Región de AWS | - | ✅ |
| `enable_alarms` | bool | Habilitar alarmas | `false` | ❌ |
| `alarm_email` | string | Email para notificaciones | `null` | ❌ |
| `lambda_error_threshold` | number | Umbral de errores Lambda | `10` | ❌ |
| `api_5xx_threshold` | number | Umbral de errores 5XX API | `10` | ❌ |
| `tags` | map(string) | Tags adicionales | `{}` | ❌ |

## Outputs

| Output | Descripción |
|--------|-------------|
| `dashboard_name` | Nombre del dashboard |
| `sns_topic_arn` | ARN del SNS topic |

## Dashboard

### Widgets Incluidos

#### 1. Lambda Metrics
```
- Invocations (Sum)
- Errors (Sum)
- Duration (Average)
```

#### 2. API Gateway Metrics
```
- Count (Sum)
- 4XXError (Sum)
- 5XXError (Sum)
```

#### 3. DynamoDB Metrics
```
- ConsumedReadCapacityUnits (Sum)
- ConsumedWriteCapacityUnits (Sum)
```

### Acceder al Dashboard

```bash
# AWS Console
CloudWatch → Dashboards → turnaki-nexioq-dev-dashboard

# URL directa
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=turnaki-nexioq-dev-dashboard
```

## Alarmas

### 1. Lambda Errors

**Trigger**: Errores Lambda > threshold en 2 períodos de 5 minutos

```hcl
Metric: AWS/Lambda - Errors
Threshold: 10 (configurable)
Evaluation Periods: 2
Period: 300 segundos (5 min)
Statistic: Sum
Action: SNS Notification
```

### 2. API Gateway 5XX Errors

**Trigger**: Errores 5XX > threshold en 2 períodos de 5 minutos

```hcl
Metric: AWS/ApiGateway - 5XXError
Threshold: 10 (configurable)
Evaluation Periods: 2
Period: 300 segundos (5 min)
Statistic: Sum
Action: SNS Notification
```

## SNS Notifications

### Email Subscription

Cuando se crea con `alarm_email`, AWS enviará un email de confirmación:

```
Subject: AWS Notification - Subscription Confirmation
Body: Click link to confirm subscription
```

**⚠️ IMPORTANTE**: Debes confirmar la suscripción haciendo clic en el enlace del email.

### Formato de Notificación

```json
{
  "AlarmName": "turnaki-nexioq-dev-lambda-errors",
  "NewStateValue": "ALARM",
  "NewStateReason": "Threshold Crossed: 2 datapoints [15.0, 12.0] were greater than the threshold (10.0).",
  "StateChangeTime": "2025-10-06T10:30:00.000+0000",
  "Region": "US East (N. Virginia)",
  "AlarmDescription": "Lambda errors exceeded threshold"
}
```

## Ejemplo Completo

```hcl
module "monitoring" {
  source = "../../modules/cloudwatch"

  project_name = "turnaki-nexioq"
  environment  = "prd"
  region       = "us-east-1"
  
  enable_alarms           = true
  alarm_email             = "alerts@turnaki.com"
  lambda_error_threshold  = 5   # Más estricto en PRD
  api_5xx_threshold       = 5

  tags = {
    Environment = "Production"
    Critical    = "Yes"
    ManagedBy   = "Terraform"
  }
}

# Agregar más suscripciones
resource "aws_sns_topic_subscription" "slack" {
  topic_arn = module.monitoring.sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier.arn
}

resource "aws_sns_topic_subscription" "pagerduty" {
  topic_arn = module.monitoring.sns_topic_arn
  protocol  = "https"
  endpoint  = "https://events.pagerduty.com/integration/..."
}

# Alarma custom adicional
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttle" {
  alarm_name          = "${var.project_name}-${var.environment}-dynamodb-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "DynamoDB throttling detected"
  alarm_actions       = [module.monitoring.sns_topic_arn]

  dimensions = {
    TableName = module.dynamodb.table_name
  }
}
```

## CloudWatch Logs Insights

### Queries Útiles

#### 1. Errores de Lambda

```
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
```

#### 2. Lambda Duration (P95)

```
filter @type = "REPORT"
| stats avg(@duration), max(@duration), pct(@duration, 95) by bin(5m)
```

#### 3. API Gateway Latency

```
fields @timestamp, latency, status, ip
| filter status >= 400
| sort latency desc
| limit 50
```

#### 4. Requests por Ruta

```
fields @timestamp, routeKey, status
| stats count() by routeKey, status
| sort count() desc
```

## Métricas Custom

### Agregar Métrica Personalizada

```rust
// En tu Lambda Rust
use aws_sdk_cloudwatch::{Client, model::*};

async fn put_metric(client: &Client, metric_name: &str, value: f64) {
    client
        .put_metric_data()
        .namespace("Turnaki/Bookings")
        .metric_data(
            MetricDatum::builder()
                .metric_name(metric_name)
                .value(value)
                .unit(StandardUnit::Count)
                .timestamp(DateTime::from_secs(chrono::Utc::now().timestamp()))
                .build()
        )
        .send()
        .await
        .unwrap();
}

// Uso
put_metric(&cloudwatch_client, "BookingCreated", 1.0).await;
```

### Agregar al Dashboard

```hcl
# En cloudwatch/main.tf
{
  type = "metric"
  properties = {
    metrics = [
      ["Turnaki/Bookings", "BookingCreated", { stat = "Sum" }],
      [".", "BookingCancelled", { stat = "Sum" }]
    ]
    period = 300
    stat   = "Sum"
    region = var.region
    title  = "Booking Metrics"
  }
}
```

## Umbrales Recomendados

### Por Ambiente

| Ambiente | Lambda Errors | API 5XX | DynamoDB Throttle |
|----------|---------------|---------|-------------------|
| Dev | 50 | 50 | 100 |
| QAS | 20 | 20 | 50 |
| PRD | 5 | 5 | 10 |

### Por Criticidad

| Criticidad | Evaluation Periods | Period | Notification |
|------------|-------------------|--------|--------------|
| Low | 3 | 900s | Email |
| Medium | 2 | 300s | Email + Slack |
| High | 1 | 60s | Email + Slack + PagerDuty |

## Costos Estimados

### CloudWatch Pricing

- **Dashboard**: $3.00/mes
- **Alarmas**: $0.10/mes por alarma
- **Métricas custom**: $0.30/mes por métrica
- **Logs**: $0.50/GB ingested

### Ejemplo: 1 dashboard, 5 alarmas, 10 métricas custom, 10GB logs

```
Dashboard:       $3.00
Alarmas:         5 × $0.10 = $0.50
Métricas custom: 10 × $0.30 = $3.00
Logs:            10GB × $0.50 = $5.00
Total: $11.50/mes
```

## Retention de Logs

### Configuración Recomendada

| Ambiente | Retention | Razón |
|----------|-----------|-------|
| Dev | 7 días | Testing, bajo costo |
| QAS | 14 días | Pre-prod, validación |
| PRD | 30-90 días | Compliance, auditoría |

## Grafana Integration (Opcional)

### Setup

```hcl
# 1. Crear API Key en AWS (IAM user)
resource "aws_iam_user" "grafana" {
  name = "grafana-cloudwatch-reader"
}

resource "aws_iam_user_policy_attachment" "grafana" {
  user       = aws_iam_user.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

# 2. En Grafana, agregar datasource CloudWatch
# Configuration → Data Sources → CloudWatch
# Auth: Access & Secret Key
# Default Region: us-east-1
```

## Convenciones de Nombres

```
Dashboard: {project_name}-{environment}-dashboard
SNS Topic: {project_name}-{environment}-alarms
Alarma: {project_name}-{environment}-{type}-{metric}
```

**Ejemplos**:
- Dashboard: `turnaki-nexioq-dev-dashboard`
- SNS Topic: `turnaki-nexioq-dev-alarms`
- Alarma: `turnaki-nexioq-dev-lambda-errors`

## Troubleshooting

### Alarma en INSUFFICIENT_DATA

```
- Verificar que las métricas existan
- Verificar que haya datos recientes
- Verificar región correcta
```

### No llegan notificaciones

```
- Verificar confirmación de suscripción SNS
- Verificar filtros de spam email
- Verificar permisos SNS
```

### Dashboard no muestra datos

```
- Verificar región correcta
- Verificar namespace de métricas
- Verificar período de tiempo seleccionado
```

## Requisitos

- Terraform >= 1.0
- AWS Provider >= 5.0
- Email válido para notificaciones

## Mantenimiento

Actualizado: Octubre 2025  
Versión: 1.0.0