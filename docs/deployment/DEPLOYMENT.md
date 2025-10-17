# 🚀 Guía de Deployment

---

## Resumen

Esta guía describe cómo desplegar **Turnaki-NexioQ** usando **Terraform** en múltiples ambientes (dev, qas, prd).

---

## Pre-requisitos

### Herramientas

- **Terraform** ≥ 1.9
- **AWS CLI** ≥ 2.x configurado
- **Node.js** ≥ 20
- **Rust** ≥ 1.75
- **cargo-lambda**

### Credenciales AWS

```bash
# Configurar perfil AWS
aws configure --profile turnaki

# O usar variables de entorno
export AWS_ACCESS_KEY_ID=<key>
export AWS_SECRET_ACCESS_KEY=<secret>
export AWS_REGION=us-east-1
```

### Permisos IAM Requeridos

- `AdministratorAccess` (recomendado para setup inicial)
- O permisos específicos para: Lambda, API Gateway, DynamoDB, Cognito, S3, CloudFront, Route53, ACM, WAF, CloudWatch, IAM

---

## Paso 1: Inicializar Backend de Terraform (Solo Primera Vez)

El backend de Terraform almacena el state en S3 con locking en DynamoDB.

```bash
cd terraform
./scripts/init-backend.sh
```

Este script crea:
- S3 bucket: `tk-nq-tfstate-<environment>` (versionado, encriptado)
- DynamoDB table: `tk-nq-tfstate-locks` (para state locking)

**Verificar**:
```bash
aws s3 ls | grep tk-nq-tfstate
aws dynamodb list-tables | grep tk-nq-tfstate-locks
```

---

## Paso 2: Deploy Ambiente Dev

### 2.1 Inicializar Terraform

```bash
cd terraform/environments/dev
terraform init
```

**Salida esperada**:
```
Initializing the backend...
Successfully configured the backend "s3"!
Terraform has been successfully initialized!
```

### 2.2 Planificar Cambios

```bash
terraform plan -out=tfplan
```

Revisar el plan:
- Recursos a crear (~50 recursos)
- Outputs esperados (API URL, S3 bucket, etc.)

### 2.3 Aplicar Cambios

```bash
terraform apply tfplan
```

**Tiempo estimado**: 10-15 minutos

**Recursos creados**:
- DynamoDB table con GSIs
- Cognito User Pool + Client
- 8 Lambda functions
- API Gateway HTTP API
- S3 bucket + CloudFront distribution
- WAF Web ACL
- CloudWatch Dashboard + Alarmas
- IAM roles y policies

### 2.4 Obtener Outputs

```bash
terraform output
```

**Outputs importantes**:
- `api_base_url`: URL de la API
- `frontend_bucket_name`: S3 bucket para frontend
- `cloudfront_distribution_id`: ID de CloudFront
- `cognito_user_pool_id`: ID del User Pool
- `cognito_client_id`: ID del Client

---

## Paso 3: Build y Deploy Backend (Lambdas)

### 3.1 Compilar Lambdas

```bash
cd ../../../backend
cargo lambda build --arm64 --release
```

**Tiempo estimado**: 5-10 minutos (primera vez)

### 3.2 Copiar Binarios

```bash
mkdir -p ../terraform/environments/dev/lambda-assets
cp target/lambda/*/bootstrap.zip ../terraform/environments/dev/lambda-assets/
```

### 3.3 Re-aplicar Terraform

```bash
cd ../terraform/environments/dev
terraform apply
```

Las Lambdas se actualizarán con los nuevos binarios.

---

## Paso 4: Build y Deploy Frontend

### 4.1 Configurar Variables de Entorno

```bash
cd ../../../frontend

# Obtener outputs de Terraform
API_URL=$(terraform -chdir=../terraform/environments/dev output -raw api_base_url)
COGNITO_DOMAIN=$(terraform -chdir=../terraform/environments/dev output -raw cognito_domain)
COGNITO_CLIENT_ID=$(terraform -chdir=../terraform/environments/dev output -raw cognito_client_id)

# Crear .env
cat > .env << EOF
VITE_API_BASE=${API_URL}
VITE_COGNITO_DOMAIN=${COGNITO_DOMAIN}
VITE_COGNITO_CLIENT_ID=${COGNITO_CLIENT_ID}
VITE_COGNITO_REDIRECT_URI=http://localhost:5173
EOF
```

### 4.2 Build Frontend

```bash
npm install
npm run build
```

**Salida**: `build/` directory

### 4.3 Deploy a S3

```bash
BUCKET=$(terraform -chdir=../terraform/environments/dev output -raw frontend_bucket_name)
aws s3 sync build/ "s3://${BUCKET}/" --delete
```

### 4.4 Invalidar CloudFront

```bash
DIST_ID=$(terraform -chdir=../terraform/environments/dev output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id "${DIST_ID}" --paths "/*"
```

---

## Paso 5: Validar Deployment

### 5.1 Health Check

```bash
API_URL=$(terraform -chdir=terraform/environments/dev output -raw api_base_url)
curl "${API_URL}/health"
```

**Esperado**:
```json
{
  "service": "health",
  "status": "ok",
  "timestamp": "2025-10-06T12:00:00Z"
}
```

### 5.2 Frontend

```bash
# Obtener URL del frontend
terraform -chdir=terraform/environments/dev output frontend_url
```

Abrir en navegador y verificar:
- ✅ Página carga correctamente
- ✅ Botón "Iniciar sesión" funciona
- ✅ Redirect a Cognito Hosted UI

### 5.3 CloudWatch Logs

```bash
# Ver logs de health Lambda
aws logs tail /aws/lambda/tk-nq-dev-health --follow
```

---

## Deploy Ambiente QAS

Similar a Dev pero con diferentes valores en `terraform.tfvars`:

```bash
cd terraform/environments/qas
terraform init
terraform plan
terraform apply
```

**Diferencias con Dev**:
- Nombres de recursos incluyen `-qas`
- Retención de logs: 30 días (vs 7 en dev)
- PITR habilitado en DynamoDB
- Diferentes dominios y certificados SSL

---

## Deploy Ambiente PRD

⚠️ **PRECAUCIÓN**: Deployment a producción requiere aprobación.

```bash
cd terraform/environments/prd
terraform init
terraform plan -out=tfplan

# Revisar plan cuidadosamente
less tfplan

# Aplicar con aprobación manual
terraform apply tfplan
```

**Diferencias con Dev/QAS**:
- Nombres de recursos incluyen `-prd`
- Retención de logs: 90 días
- Backups automáticos (AWS Backup)
- Multi-AZ para DynamoDB
- CloudFront con múltiples origins
- WAF rules más estrictas

---

## Rollback

### Rollback de Terraform

```bash
# Ver versiones anteriores del state
aws s3 ls s3://tk-nq-tfstate-dev/ --recursive | grep terraform.tfstate

# Descargar versión anterior
aws s3 cp s3://tk-nq-tfstate-dev/terraform.tfstate.backup terraform.tfstate

# Re-aplicar
terraform apply
```

### Rollback de Lambda

```bash
# Listar versiones
aws lambda list-versions-by-function --function-name tk-nq-dev-health

# Actualizar a versión anterior
aws lambda update-function-code \
  --function-name tk-nq-dev-health \
  --s3-bucket <bucket> \
  --s3-key lambda/health-v1.zip
```

---

## Troubleshooting

### Error: "state lock"

```bash
# Forzar unlock
terraform force-unlock <LOCK_ID>
```

### Error: "certificate validation pending"

```bash
# Esperar 5-10 minutos para validación DNS automática
# O verificar registros CNAME en Route53
aws route53 list-resource-record-sets --hosted-zone-id <ZONE_ID>
```

### Error: Lambda timeout

```bash
# Aumentar timeout en Terraform
# terraform/modules/lambda/main.tf
timeout = 30  # aumentar de 10 a 30

terraform apply
```

Ver [RUNBOOK.md](RUNBOOK.md#troubleshooting-común) para más detalles.

---

## CI/CD (Dev 100% en AWS)

### GitHub Actions (deploy + QA)

El workflow `.github/workflows/deploy-dev.yml` realiza:
- Validación de Terraform y módulos
- Deploy de infraestructura (dev) con OIDC
- Build y deploy de Lambdas (Rust) y Frontend (S3 + CloudFront)
- Seeds de DynamoDB con TZ `America/Guayaquil`
- Tests unitarios (Rust + Vitest)
- Tests E2E contra CloudFront (login real Cognito)
- Seguridad (ZAP baseline + WAF negativos)
- Performance (k6)

Secrets requeridos en GitHub:
- `AWS_ROLE_TO_ASSUME` (ver `setup-aws-oidc.sh`)
- `E2E_USER_EMAIL` y `E2E_USER_PASSWORD` (usuario de pruebas Cognito)

Variables/outputs usados:
- `cloudfront_url`, `frontend_bucket_name`, `api_endpoint`
- `cognito_user_pool_id`, `cognito_client_id`, `cognito_domain`

Trigger: push a `main`.

---

## Comandos Útiles

```bash
# Ver todos los outputs
terraform output

# Ver output específico
terraform output -raw api_base_url

# Refresh state
terraform refresh

# Validar sintaxis
terraform validate

# Format código
terraform fmt -recursive

# Ver resources
terraform state list

# Ver detalles de un recurso
terraform state show aws_lambda_function.health

# Destroy ambiente (⚠️ CUIDADO)
terraform destroy
```

---

## Checklist de Deployment

### Pre-deployment

- [ ] Credenciales AWS configuradas
- [ ] Terraform instalado (≥1.9)
- [ ] Backend de Terraform inicializado
- [ ] Variables de entorno configuradas

### Deployment

- [ ] `terraform init` exitoso
- [ ] `terraform plan` revisado
- [ ] `terraform apply` completado sin errores
- [ ] Lambdas compiladas y desplegadas
- [ ] Frontend buildeado y subido a S3
- [ ] CloudFront invalidado

### Post-deployment

- [ ] Health check pasando
- [ ] Frontend cargando correctamente
- [ ] Autenticación funcionando
- [ ] CloudWatch logs visibles
- [ ] Alarmas configuradas
- [ ] Tests E2E pasando

---

**Última actualización**: Octubre 2025  
**Versión**: 2.0.0
