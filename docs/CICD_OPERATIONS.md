# 🚀 Guía de Operaciones CI/CD

**Proyecto**: Turnaki-NexioQ  
**Fecha**: Octubre 2025  
**Versión**: 2.2.0

---

## 📋 Resumen Ejecutivo

El sistema CI/CD de Turnaki-NexioQ está completamente configurado y operativo con:

- ✅ Deployment automático en **dev** al hacer merge a `main`
- ✅ Deployment controlado en **qas** y **prd** con aprobaciones requeridas
- ✅ Validación automática con Terraform plan en cada PR
- ✅ Health checks automáticos post-deployment
- ✅ AWS OIDC integrado (sin access keys en código)

---

## 🔄 Flujo de Trabajo

### Desarrollo Normal

```
1. Crear feature branch
   git checkout -b feature/nueva-funcionalidad

2. Hacer cambios y commit
   git add .
   git commit -m "feat: agregar nueva funcionalidad"

3. Push y crear PR
   git push origin feature/nueva-funcionalidad
   # Crear PR en GitHub

4. Workflow terraform-plan se ejecuta automáticamente
   ✅ Plan visible en comentario del PR

5. Después de code review, merge a main
   # El PR se aprueba y se hace merge

6. Workflow terraform-apply-dev se ejecuta automáticamente
   ✅ Deployment a dev completo (~8-12 min)
   ✅ Health checks pasan
   ✅ Comentario con URLs de deployment

7. Deploy a producción (manual cuando esté listo)
   gh workflow run terraform-apply-prd.yml -f confirm=yes
```

### Deployment Manual a QAS/PRD

```bash
# Deploy a QAS
gh workflow run terraform-apply-qas.yml

# Deploy a PRD (requiere confirmación)
gh workflow run terraform-apply-prd.yml -f confirm=yes
```

---

## 🔍 Validación de Configuración

### Script de Validación

El script `scripts/validate-cicd-setup.sh` verifica:

- ✅ Comandos necesarios instalados (aws, terraform, gh, git)
- ✅ AWS CLI configurado correctamente
- ✅ GitHub CLI autenticado
- ✅ OIDC Provider existente
- ✅ Roles IAM creados
- ✅ Secrets configurados en GitHub
- ✅ Workflows presentes en `.github/workflows/`

**Uso**:
```bash
./scripts/validate-cicd-setup.sh
```

### Checklist Manual

Si prefieres verificar manualmente:

- [ ] AWS OIDC Provider existe: `arn:aws:iam::008344241886:oidc-provider/token.actions.githubusercontent.com`
- [ ] Rol dev existe: `github-actions-terraform-dev`
- [ ] Rol prd existe: `github-actions-terraform-prd`
- [ ] Secret `AWS_ROLE_TO_ASSUME` configurado en GitHub
- [ ] Secret `AWS_ROLE_TO_ASSUME_PRD` configurado en GitHub
- [ ] Environments creados en GitHub UI: dev, qas, prd

---

## 🐛 Troubleshooting

### Error: "Could not assume role"

**Causa**: Trust policy incorrecto o ARN del rol mal configurado.

**Solución**:
```bash
# Verificar trust policy
aws iam get-role --role-name github-actions-terraform-dev

# Verificar que el sub coincida con tu repo
# Debe ser: "repo:juniorcbss/turnaki-nexioq:*"
```

### Error: "Backend initialization failed"

**Causa**: No hay acceso al bucket S3 del tfstate.

**Solución**:
```bash
# Verificar acceso
aws s3 ls s3://turnaki-nexioq-terraform-state/

# Verificar políticas del rol
aws iam list-attached-role-policies --role-name github-actions-terraform-dev
aws iam get-role-policy --role-name github-actions-terraform-dev --policy-name TerraformStateAccess
```

### Error: "Workflow no se ejecuta automáticamente"

**Causa**: Environments no creados o protecciones incorrectas.

**Solución**:
1. Ve a GitHub → Settings → Environments
2. Verifica que existen: dev, qas, prd
3. Verifica que dev NO tiene protecciones (deployment libre)
4. Verifica que qas/prd tienen required reviewers configurados

### Error: "Health check failed"

**Causa**: Lambda o API Gateway no se desplegaron correctamente.

**Solución**:
```bash
# Ver logs del workflow
gh run view <run-id> --log

# Verificar que Lambdas estén desplegadas
aws lambda list-functions --query 'Functions[?contains(FunctionName, `turnaki-nexioq-dev`)].FunctionName'

# Test manual del health endpoint
curl https://mqp7tk0dkh.execute-api.us-east-1.amazonaws.com/health
```

---

## 🔄 Proceso de Rollback

### Rollback Automático

Si un deployment falla en el health check, el workflow falla y no se aplican cambios.

### Rollback Manual de Infraestructura

```bash
# Opción 1: Usar terraform plan/apply con estado anterior
cd terraform/environments/dev
terraform state list
terraform state show <resource>  # Ver estado anterior
terraform plan -refresh-only    # Ver diferencias

# Opción 2: Usar Terraform rollback
terraform apply -state=<previous-state-file>
```

### Rollback de Lambdas

```bash
# Listar versiones disponibles
aws lambda list-versions-by-function --function-name tk-nq-dev-bookings

# Publicar una versión específica
aws lambda update-function-code \
  --function-name tk-nq-dev-bookings \
  --zip-file fileb://bootstrap.zip
```

### Rollback de Frontend

```bash
# Invalidar CloudFront y subir versión anterior
aws cloudfront create-invalidation --distribution-id <dist-id> --paths "/*"

# Subir versión anterior desde git
git checkout <previous-commit>
cd frontend
npm run build
aws s3 sync build/ s3://<bucket-name>/
```

---

## 🧪 Testing del CI/CD

### Test 1: Terraform Plan

```bash
# Crear PR de prueba
git checkout -b test/cicd-validation
echo "# Test" >> terraform/README.md
git add terraform/README.md
git commit -m "test: validar workflow terraform-plan"
git push origin test/cicd-validation

# Crear PR en GitHub y verificar que terraform-plan se ejecuta
```

### Test 2: Terraform Apply Dev

```bash
# Después de que el plan sea exitoso, hacer merge
# Verificar que terraform-apply-dev se ejecuta automáticamente
gh run list --workflow=terraform-apply-dev.yml

# Ver logs
gh run view <run-id> --log
```

### Test 3: Endpoints Post-Deployment

```bash
# Health check
curl https://mqp7tk0dkh.execute-api.us-east-1.amazonaws.com/health

# Frontend
curl -I https://d2rwm4uq5d71nu.cloudfront.net
```

---

## 📊 Monitoreo

### Métricas Clave

- **Tiempo de deployment**: Dev (~8-12 min), QAS (~10-15 min), PRD (~10-15 min)
- **Success rate**: Target >95%
- **Health check pass rate**: Target 100%

### CloudWatch Dashboard

Dashboard disponible en AWS Console:
- Nombre: `turnaki-nexioq-dev-dashboard`
- Métricas: Lambda invocations, errors, duration
- API Gateway: Count, 4XX, 5XX
- DynamoDB: Read/Write capacity

### Alarmas Configuradas

1. **Lambda Errors** > 10 en 5 min
2. **API Gateway 5XX** > 10 en 5 min
3. **Lambda Throttles** > 0
4. **DynamoDB Capacity** > 10,000 unidades en 5 min
5. **WAF Blocked** > 100 requests en 5 min

---

## 🔒 Seguridad

### OIDC Configuration

- Provider URL: `https://token.actions.githubusercontent.com`
- Client ID: `sts.amazonaws.com`
- Thumbprint: `6938fd4d98bab03faadb97b34396831e3780aea1`

### Trust Policies

**Dev**:
```json
{
  "Condition": {
    "StringLike": {
      "token.actions.githubusercontent.com:sub": "repo:juniorcbss/turnaki-nexioq:*"
    }
  }
}
```

**PRD**:
```json
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:sub": "repo:juniorcbss/turnaki-nexioq:ref:refs/heads/main"
    }
  }
}
```

### Rotación de Secrets

Los secrets de OIDC NO requieren rotación manual (tokens temporales de 1 hora).

---

## 📚 Referencias

- [Workflows Documentation](.github/workflows/README.md)
- [Secrets Setup](.github/SECRETS_SETUP.md)
- [Deployment Guide](deployment/DEPLOYMENT.md)
- [AWS OIDC with GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

---

## 🎯 Mejores Prácticas

1. **Nunca hacer merge sin revisar el terraform plan** en el PR
2. **Validar health checks** después de cada deployment
3. **Monitorear alarmas** diariamente en CloudWatch
4. **Hacer rollback inmediato** si hay errores en producción
5. **Documentar cambios significativos** en CHANGELOG.md
6. **Usar feature branches** para cambios grandes
7. **Validar configuración** antes de deployments críticos

---

**Última actualización**: Octubre 2025  
**Mantenido por**: DevOps Team Turnaki-NexioQ

