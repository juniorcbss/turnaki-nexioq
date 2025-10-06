# 🔐 Configuración de Secrets para GitHub Actions

Este documento explica cómo configurar los secrets necesarios para ejecutar los workflows de CI/CD con Terraform.

---

## 📋 Secrets Requeridos

### Opción 1: AWS Access Keys (Más Simple)

| Secret Name | Descripción | Valor de Ejemplo |
|------------|-------------|------------------|
| `AWS_ACCESS_KEY_ID` | Access Key ID de AWS | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Secret Access Key de AWS | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |

**Nota:** No se recomienda para producción. Usar OIDC (Opción 2) es más seguro.

### Opción 2: AWS OIDC (Recomendado para Producción)

| Secret Name | Descripción | Valor de Ejemplo |
|------------|-------------|------------------|
| `AWS_ROLE_TO_ASSUME` | ARN del rol IAM para dev/qas | `arn:aws:iam::123456789012:role/github-actions-terraform-dev` |
| `AWS_ROLE_TO_ASSUME_PRD` | ARN del rol IAM para prd | `arn:aws:iam::123456789012:role/github-actions-terraform-prd` |

---

## 🛠️ Setup Paso a Paso

### Opción 1: Configurar con AWS Access Keys

#### 1. Crear Usuario IAM

```bash
aws iam create-user --user-name github-actions-terraform

# Crear access keys
aws iam create-access-key --user-name github-actions-terraform
```

#### 2. Asignar Permisos

Crear archivo `github-actions-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:*",
        "lambda:*",
        "apigateway:*",
        "cognito-idp:*",
        "s3:*",
        "cloudfront:*",
        "iam:*",
        "logs:*",
        "cloudwatch:*",
        "wafv2:*",
        "ses:*",
        "xray:*",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::tk-nq-backups-tfstate/*"
    }
  ]
}
```

Aplicar política:

```bash
aws iam put-user-policy \
  --user-name github-actions-terraform \
  --policy-name TerraformFullAccess \
  --policy-document file://github-actions-policy.json
```

#### 3. Agregar Secrets en GitHub

1. Ve a tu repositorio en GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Agregar:
   - Name: `AWS_ACCESS_KEY_ID`
   - Secret: `<tu-access-key-id>`
5. Repetir para `AWS_SECRET_ACCESS_KEY`

---

### Opción 2: Configurar con OIDC (Recomendado) 🌟

#### 1. Crear OIDC Provider en AWS

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### 2. Crear Rol IAM para GitHub Actions

Crear archivo `trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::TU-ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:TU-ORG/turnaki-nexioq:*"
        }
      }
    }
  ]
}
```

Crear rol:

```bash
# Rol para Dev/QAS
aws iam create-role \
  --role-name github-actions-terraform-dev \
  --assume-role-policy-document file://trust-policy.json

# Rol para PRD (más restrictivo)
aws iam create-role \
  --role-name github-actions-terraform-prd \
  --assume-role-policy-document file://trust-policy-prd.json
```

#### 3. Asignar Políticas al Rol

```bash
# Política administrada de AWS
aws iam attach-role-policy \
  --role-name github-actions-terraform-dev \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Política personalizada
aws iam put-role-policy \
  --role-name github-actions-terraform-dev \
  --policy-name TerraformStateAccess \
  --policy-document file://github-actions-policy.json
```

#### 4. Agregar ARN del Rol como Secret en GitHub

1. Ve a **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Agregar:
   - Name: `AWS_ROLE_TO_ASSUME`
   - Secret: `arn:aws:iam::123456789012:role/github-actions-terraform-dev`
4. Agregar para producción:
   - Name: `AWS_ROLE_TO_ASSUME_PRD`
   - Secret: `arn:aws:iam::123456789012:role/github-actions-terraform-prd`

---

## 🔒 Configurar Environments en GitHub

Para tener aprobaciones manuales antes de desplegar:

### 1. Crear Environments

1. Ve a **Settings** → **Environments**
2. Click **New environment**
3. Crear 3 environments:
   - `dev` (sin protecciones)
   - `qas` (protección: required reviewers)
   - `prd` (protección: required reviewers + branch restriction)

### 2. Configurar Protecciones para QAS

1. Select environment `qas`
2. **Required reviewers**: Agregar 1+ personas
3. **Deployment branches**: `Selected branches` → `main`

### 3. Configurar Protecciones para PRD

1. Select environment `prd`
2. **Required reviewers**: Agregar 2+ personas (DevOps lead + Tech lead)
3. **Deployment branches**: `Selected branches` → `main` only
4. **Wait timer**: 5 minutos (opcional)
5. **Environment secrets** (opcional): Sobreescribir `AWS_ROLE_TO_ASSUME_PRD`

---

## ✅ Verificar Configuración

### Test Manual en GitHub Actions

1. Ve a **Actions** tab
2. Selecciona workflow `Terraform Plan`
3. Click **Run workflow**
4. Si todo está bien configurado:
   - ✅ Validation pasa
   - ✅ Plan se ejecuta sin errores de autenticación
   - ✅ Comentario aparece en el PR (si es PR)

### Test desde CLI

```bash
# Verificar que el rol OIDC funciona
gh workflow run terraform-plan.yml

# Ver logs
gh run list --workflow=terraform-plan.yml
gh run view <run-id> --log
```

---

## 🐛 Troubleshooting

### Error: "Could not assume role"

**Causa:** Trust policy incorrecto o ARN del rol mal configurado.

**Solución:**

```bash
# Verificar trust policy del rol
aws iam get-role --role-name github-actions-terraform-dev

# Verificar que el sub del token.actions.githubusercontent.com coincide
# debe ser: "repo:TU-ORG/turnaki-nexioq:*"
```

### Error: "Access Denied" al hacer terraform apply

**Causa:** Rol no tiene permisos suficientes.

**Solución:**

```bash
# Ver políticas del rol
aws iam list-attached-role-policies --role-name github-actions-terraform-dev

# Agregar política faltante
aws iam attach-role-policy \
  --role-name github-actions-terraform-dev \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

### Error: "Backend initialization failed"

**Causa:** No hay acceso al bucket S3 del tfstate.

**Solución:**

Verificar que el rol tiene acceso al bucket:

```bash
aws s3 ls s3://tk-nq-backups-tfstate/ --profile github-actions

# Si no funciona, agregar política:
{
  "Effect": "Allow",
  "Action": ["s3:*"],
  "Resource": [
    "arn:aws:s3:::tk-nq-backups-tfstate",
    "arn:aws:s3:::tk-nq-backups-tfstate/*"
  ]
}
```

---

## 📊 Matriz de Permisos Recomendados

| Servicio | Dev/QAS | PRD | Notas |
|----------|---------|-----|-------|
| DynamoDB | Full | Full | Necesario para crear/modificar tablas |
| Lambda | Full | Full | Deploy de funciones |
| API Gateway | Full | Full | Actualizar rutas |
| Cognito | Full | Read-only | PRD no debería modificar user pool |
| S3 | Full | Write-only | PRD solo sube archivos al bucket de frontend |
| CloudFront | Full | Full | Invalidaciones necesarias |
| IAM | Limited | None | Solo crear roles para lambdas |
| CloudWatch | Full | Full | Logs y métricas |
| WAF | Full | Read-only | PRD no debería modificar reglas |

---

## 🔄 Rotación de Secrets

### Para Access Keys (Opción 1)

```bash
# 1. Crear nueva access key
aws iam create-access-key --user-name github-actions-terraform

# 2. Actualizar secrets en GitHub

# 3. Esperar 24 horas para validar

# 4. Eliminar access key antigua
aws iam delete-access-key \
  --user-name github-actions-terraform \
  --access-key-id <OLD-KEY-ID>
```

### Para OIDC (Opción 2)

No requiere rotación manual. El token es temporal (1 hora) y se genera automáticamente.

---

## 📚 Referencias

- [GitHub Actions OIDC con AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform en GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

---

**Creado:** Octubre 2025  
**Última actualización:** Octubre 2025  
**Autor:** DevOps Team Turnaki-NexioQ
