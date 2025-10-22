# 🎯 Instrucciones para Completar Tareas Pendientes

**Fecha**: Octubre 2025  
**Estado Actual**: 73% Completado (11/15 tareas)  
**Tareas Pendientes**: 4 tareas

---

## 📋 Resumen Rápido

### ✅ Completado (11/15)

- Todas las tareas técnicas implementables ✅
- AWS OIDC configurado ✅
- Secrets configurados ✅
- Mejoras de seguridad implementadas ✅
- Documentación completa ✅
- PR de prueba creado (#2) ✅

### ⏳ Pendiente (4/15)

1. Crear environments qas y prd (manual)
2. Investigar error del workflow
3. Validar terraform-apply-dev
4. Validar health checks

---

## 🚀 Tarea 1: Crear Environments en GitHub UI

### Estado Actual

- ✅ Environment `dev` existe
- ⏳ Environment `qas` NO existe
- ⏳ Environment `prd` NO existe

### Pasos Detallados

1. **Abrir GitHub UI**:
   ```
   https://github.com/juniorcbss/turnaki-nexioq/settings/environments
   ```

2. **Crear Environment `qas`**:
   - Click en "New environment"
   - Nombre: `qas`
   - Agregar configuración:
     - ✅ **Required reviewers**: Seleccionar al menos 1 persona
     - ✅ **Deployment branches**: "Selected branches" → Seleccionar `main`
   - Click "Save environment"

3. **Crear Environment `prd`**:
   - Click en "New environment"
   - Nombre: `prd`
   - Agregar configuración:
     - ✅ **Required reviewers**: Seleccionar al menos 2 personas
     - ✅ **Deployment branches**: "Selected branches" → Seleccionar `main`
     - ⏱️ **Wait timer**: 5 minutos (opcional pero recomendado)
   - Click "Save environment"

**Tiempo estimado**: 5 minutos

---

## 🔍 Tarea 2: Investigar Error del Workflow

### Estado Actual

- PR #2 creado: https://github.com/juniorcbss/turnaki-nexioq/pull/2
- Workflow terraform-plan falló
- Run ID: 18706969383

### Pasos para Investigar

```bash
# Ver detalles del workflow fallido
gh run view 18706969383

# Ver logs completos
gh run view 18706969383 --log

# Ver estado del PR
gh pr view 2

# Ver comentarios del bot
gh pr view 2 --comments
```

### Posibles Causas del Error

1. **Falta de environments**: Los workflows pueden requerir environments específicos
2. **Configuración de secrets**: Puede haber problemas con los secrets configurados
3. **Permisos del rol**: El rol IAM puede no tener permisos suficientes
4. **Backend de Terraform**: Puede haber problemas con el bucket S3 o tabla DynamoDB

### Comandos de Diagnóstico

```bash
# Verificar configuración de secrets
gh secret list

# Verificar rol IAM en AWS
aws iam get-role --role-name github-actions-terraform-dev

# Verificar backend de Terraform
aws s3 ls s3://turnaki-nexioq-terraform-state/
aws dynamodb describe-table --table-name turnaki-nexioq-terraform-locks
```

**Tiempo estimado**: 10-15 minutos

---

## ✅ Tarea 3: Validar Workflow terraform-apply-dev

### Estado Actual

- Esperando que terraform-plan sea exitoso primero

### Pasos

```bash
# 1. Una vez que terraform-plan sea exitoso, hacer merge del PR
gh pr merge 2 --merge

# 2. Monitorear el workflow terraform-apply-dev
gh run list --workflow=terraform-apply-dev.yml
gh run watch

# 3. Ver logs en tiempo real
gh run view <run-id> --log
```

### Qué Esperar

- ✅ Workflow se ejecuta automáticamente después del merge
- ✅ Terraform apply exitoso
- ✅ Lambdas actualizadas (si hay cambios)
- ✅ Frontend desplegado (si hay cambios)
- ✅ Health check pasa automáticamente

**Tiempo estimado**: 15-20 minutos

---

## 🔍 Tarea 4: Validar Health Checks

### Estado Actual

- Esperando deployment exitoso

### Pasos

```bash
# Health check de la API
curl https://mqp7tk0dkh.execute-api.us-east-1.amazonaws.com/health

# Expected response:
# {"service":"health","status":"ok"}

# Health check del frontend
curl -I https://d2rwm4uq5d71nu.cloudfront.net

# Expected response:
# HTTP/2 200
```

### Verificar Logs

```bash
# Ver logs de CloudWatch
aws logs tail /aws/lambda/tk-nq-dev-health --follow

# Ver métricas de CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=tk-nq-dev-health \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

**Tiempo estimado**: 5 minutos

---

## 📊 Checklist de Validación Completa

### Configuración ✅

- [x] AWS OIDC Provider creado
- [x] Roles IAM creados con políticas correctas
- [x] Secrets configurados en GitHub
- [ ] Environments creados en GitHub UI ⏳

### Workflows ⏳

- [x] PR de prueba creado (#2)
- [ ] Workflow terraform-plan ejecuta sin errores ⏳
- [ ] Workflow terraform-apply-dev ejecuta automáticamente ⏳
- [ ] Health checks pasan ⏳

### Infraestructura ⏳

- [ ] Terraform apply exitoso ⏳
- [ ] Lambdas actualizadas ⏳
- [ ] Frontend desplegado ⏳
- [ ] Endpoints responden correctamente ⏳

---

## 🎯 Secuencia de Ejecución Recomendada

### Paso 1: Crear Environments (5 min)
```bash
# Abrir en navegador
open https://github.com/juniorcbss/turnaki-nexioq/settings/environments
```

### Paso 2: Investigar Error (10-15 min)
```bash
gh run view 18706969383 --log
```

### Paso 3: Corregir Problema
Basado en lo encontrado en el paso 2

### Paso 4: Re-validar (opcional)
```bash
# Crear nuevo PR de prueba si es necesario
./scripts/complete-cicd-validation.sh
```

### Paso 5: Merge y Deployment (15-20 min)
```bash
gh pr merge 2 --merge
gh run watch
```

### Paso 6: Validar Health Checks (5 min)
```bash
curl https://mqp7tk0dkh.execute-api.us-east-1.amazonaws.com/health
```

**Total estimado**: 35-45 minutos

---

## 🐛 Troubleshooting Común

### Error: "Could not assume role"

**Causa**: Trust policy incorrecto

**Solución**:
```bash
# Verificar trust policy
aws iam get-role --role-name github-actions-terraform-dev

# Verificar que el "sub" coincida con tu repo
# Debe ser: "repo:juniorcbss/turnaki-nexioq:*"
```

### Error: "Backend initialization failed"

**Causa**: No hay acceso al bucket S3

**Solución**:
```bash
# Verificar acceso
aws s3 ls s3://turnaki-nexioq-terraform-state/

# Verificar políticas del rol
aws iam get-role-policy --role-name github-actions-terraform-dev --policy-name TerraformStateAccess
```

### Error: "Workflow not running"

**Causa**: Environments no creados

**Solución**: Crear environments en GitHub UI

---

## 📞 Recursos de Ayuda

### Documentación
- `docs/CICD_OPERATIONS.md` - Guía de operaciones
- `docs/ESTADO_TAREAS_PENDIENTES.md` - Estado detallado
- `.github/SECRETS_SETUP.md` - Setup de secrets

### Scripts
- `scripts/validate-cicd-setup.sh` - Validar configuración
- `scripts/complete-cicd-validation.sh` - Automatizar validación

### Comandos Útiles
```bash
# Ver workflows
gh run list

# Ver PRs
gh pr list

# Ver estado
gh pr view 2

# Validar AWS
aws sts get-caller-identity
```

---

## ✅ Criterios de Éxito Final

Una vez completadas todas las tareas:

- ✅ Todos los environments creados
- ✅ Workflow terraform-plan ejecuta exitosamente
- ✅ Workflow terraform-apply-dev ejecuta automáticamente
- ✅ Health checks pasan
- ✅ Deployment automático funcionando en dev
- ✅ Sistema CI/CD 100% operativo

---

**Última actualización**: Octubre 2025  
**Mantenido por**: DevOps Team Turnaki-NexioQ

