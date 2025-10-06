# 📚 RUNBOOK — Operaciones Turnaki-NexioQ

Este documento describe los procedimientos operativos para administrar la infraestructura del proyecto **Turnaki-NexioQ** (plataforma SaaS de reservas odontológicas).

---

## Tabla de Contenidos

1. [Pre-requisitos](#pre-requisitos)
2. [Deployment con Terraform](#deployment-con-terraform)
3. [Rollback y Recuperación](#rollback-y-recuperación)
4. [Monitoreo y Logs](#monitoreo-y-logs)
5. [Troubleshooting Común](#troubleshooting-común)
6. [Comandos Útiles](#comandos-útiles)

---

## Pre-requisitos

### Herramientas Locales

- **Terraform** ≥ 1.9
- **Node.js** ≥ 20.x
- **Rust** ≥ 1.75 + cargo-lambda
- **AWS CLI v2** configurado

### Credenciales AWS

```bash
# Verificar cuenta/región activa
aws sts get-caller-identity
aws configure get region
```

---

## Deployment con Terraform

### 1. Inicializar Backend (Solo Primera Vez)

```bash
cd terraform
./scripts/init-backend.sh
```

Este script crea:
- S3 bucket para tfstate
- DynamoDB table para state locking

### 2. Deploy Ambiente Dev

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### 3. Build y Deploy Lambdas

```bash
cd backend
cargo lambda build --arm64 --release

# Copiar binarios a directorio de assets
cp target/lambda/*/bootstrap.zip ../terraform/environments/dev/lambda-assets/

# Re-aplicar terraform para actualizar lambdas
cd ../terraform/environments/dev
terraform apply
```

### 4. Deploy Frontend

```bash
cd frontend
npm run build

# Obtener nombre del bucket de los outputs de Terraform
BUCKET=$(terraform -chdir=../../terraform/environments/dev output -raw frontend_bucket_name)

# Subir a S3
aws s3 sync build/ "s3://${BUCKET}/"

# Invalidar CloudFront
DIST_ID=$(terraform -chdir=../../terraform/environments/dev output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id "${DIST_ID}" --paths "/*"
```

---

## Rollback y Recuperación

### Rollback de Terraform

```bash
# Ver historial de states
cd terraform/environments/dev
terraform state list

# Rollback a versión anterior del state (desde S3)
aws s3 cp s3://tk-nq-tfstate-dev/terraform.tfstate.backup terraform.tfstate

# O usar Terraform Cloud/Enterprise time travel
```

### Rollback de Lambda

```bash
# Listar versiones
aws lambda list-versions-by-function --function-name tk-nq-dev-health

# Actualizar alias a versión anterior
aws lambda update-alias \
  --function-name tk-nq-dev-health \
  --name production \
  --function-version 5
```

### Recuperar de Estado Corrupto

```bash
# Eliminar state lock si está stuck
aws dynamodb delete-item \
  --table-name tk-nq-tfstate-locks \
  --key '{"LockID":{"S":"tk-nq-dev/terraform.tfstate"}}'

# Re-aplicar terraform
terraform init -reconfigure
terraform plan
terraform apply
```

---

## Monitoreo y Logs

### CloudWatch Logs

```bash
# Logs en tiempo real de una Lambda
aws logs tail /aws/lambda/tk-nq-dev-health --follow

# Búsqueda de errores en últimas 24 horas
aws logs filter-log-events \
  --log-group-name /aws/lambda/tk-nq-dev-bookings \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '24 hours ago' +%s000)
```

### CloudWatch Metrics

```bash
# Invocaciones de Lambda en última hora
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=tk-nq-dev-health \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

### Dashboard CloudWatch

Acceder al dashboard `tk-nq-api-metrics`:

```bash
# Abrir en navegador
aws cloudwatch get-dashboard --dashboard-name tk-nq-api-metrics
```

Ver métricas de:
- Invocaciones por Lambda
- Errores y throttles
- Latencia (p50, p99)
- API Gateway requests

### X-Ray Traces

```bash
# Obtener traces de última hora
aws xray get-trace-summaries \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --filter-expression 'service("tk-nq-dev-availability")'
```

---

## Troubleshooting Común

### 1. Terraform State Locked

**Síntoma**: `Error acquiring the state lock`

**Causa**: Otro proceso está ejecutando terraform o un proceso anterior falló sin liberar el lock.

**Solución**:
```bash
# Forzar unlock (con precaución)
terraform force-unlock <LOCK_ID>

# O eliminar lock de DynamoDB
aws dynamodb delete-item \
  --table-name tk-nq-tfstate-locks \
  --key '{"LockID":{"S":"<LOCK_ID>"}}'
```

### 2. Lambda Timeout

**Síntoma**: Errores 5xx en API, logs muestran "Task timed out"

**Causa**: Función Lambda excede el timeout configurado (default: 10s)

**Solución**:
```bash
# Aumentar timeout en Terraform
# terraform/modules/lambda/main.tf
resource "aws_lambda_function" "function" {
  timeout = 30  # aumentar a 30 segundos
}

terraform apply
```

### 3. DynamoDB Throttling

**Síntoma**: Errores `ProvisionedThroughputExceededException`

**Causa**: RCU/WCU insuficientes o ráfaga de tráfico excede burst capacity

**Solución**:
```bash
# Cambiar a on-demand (en terraform)
# terraform/modules/dynamodb/main.tf
resource "aws_dynamodb_table" "main" {
  billing_mode = "PAY_PER_REQUEST"
}

terraform apply
```

### 4. CloudFront 403 Forbidden

**Síntoma**: Frontend no carga, CloudFront devuelve 403

**Causa**: Bucket policy o OAI mal configurado

**Solución**:
```bash
# Verificar bucket policy
BUCKET=$(terraform output -raw frontend_bucket_name)
aws s3api get-bucket-policy --bucket "${BUCKET}"

# Re-aplicar terraform para arreglar permisos
terraform apply -target=module.s3_cloudfront
```

### 5. Certificado SSL Pending Validation

**Síntoma**: HTTPS no funciona, certificado en `PENDING_VALIDATION`

**Causa**: DNS validation no completada

**Solución**:
```bash
# Verificar registros DNS en Route53
aws route53 list-resource-record-sets --hosted-zone-id <ZONE_ID>

# Esperar 5-10 minutos para propagación
# O forzar re-validación
terraform taint module.s3_cloudfront.aws_acm_certificate.cert
terraform apply
```

### 6. API Gateway 401 Unauthorized

**Síntoma**: Peticiones autenticadas rechazan con 401

**Causa**: JWT token expirado o inválido

**Solución**:
```bash
# Verificar token en frontend
# Consola del navegador:
console.log(localStorage.getItem('tk_nq_token'));

# Decodificar en https://jwt.io/
# Verificar:
# - iss: https://cognito-idp.us-east-1.amazonaws.com/<USER_POOL_ID>
# - exp: no expirado
# - aud: <CLIENT_ID> correcto
```

---

## Comandos Útiles

### Terraform

```bash
# Ver outputs
terraform output

# Ver state
terraform state list
terraform state show aws_lambda_function.health

# Refresh state sin modificar
terraform refresh

# Validar sintaxis
terraform validate

# Format código
terraform fmt -recursive

# Planificar cambios específicos
terraform plan -target=module.lambda.aws_lambda_function.bookings
```

### AWS CLI

```bash
# Listar todas las Lambdas
aws lambda list-functions --query "Functions[?starts_with(FunctionName, 'tk-nq')].FunctionName"

# Ver configuración de Lambda
aws lambda get-function-configuration --function-name tk-nq-dev-health

# Invocar Lambda manualmente
aws lambda invoke \
  --function-name tk-nq-dev-health \
  --payload '{}' \
  response.json

# Listar stacks de CloudFormation (si hay legacy CDK)
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE
```

### DynamoDB

```bash
# Scan tabla (cuidado en producción)
aws dynamodb scan --table-name tk-nq-dev-main --limit 10

# Query por PK
aws dynamodb query \
  --table-name tk-nq-dev-main \
  --key-condition-expression "PK = :pk" \
  --expression-attribute-values '{":pk":{"S":"TENANT#site-1"}}'

# Contar items
aws dynamodb scan --table-name tk-nq-dev-main --select COUNT
```

---

## Contacto y Escalamiento

Para incidentes críticos:

- **DevOps Lead**: devops@turnaki.com
- **Slack**: `#turnaki-infra`
- **PagerDuty**: (configurar)

### SLA

- **P0 (Crítico)**: Respuesta < 15 min, Resolución < 2 horas
- **P1 (Alto)**: Respuesta < 1 hora, Resolución < 8 horas
- **P2 (Medio)**: Respuesta < 4 horas, Resolución < 24 horas

---

**Última actualización**: Octubre 2025  
**Versión**: 2.0 (Terraform)
