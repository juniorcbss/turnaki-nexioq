# 🚀 Próximos Pasos Prioritarios

**Proyecto**: Turnaki-NexioQ  
**Fecha**: 6 de Octubre 2025  
**Estado**: ✅ Fases 1-6 completadas al 100%

---

## ✅ Lo que ya está hecho

- ✅ **9 módulos Terraform** implementados y documentados
- ✅ **3 ambientes** configurados (dev, qas, prd)
- ✅ **8 workflows CI/CD** creados y documentados
- ✅ **Backend Rust** con 8 lambdas funcionando
- ✅ **Frontend Svelte 5** con PWA
- ✅ **Documentación completa** actualizada
- ✅ **Commit creado**: `248b1c4` con todos los cambios de Fase 6

---

## 🎯 Los 5 Pasos Siguientes (En Orden)

### ✅ Paso 1: Push del Commit a GitHub

**Estado**: ✅ COMPLETADO (commit `248b1c4` creado)

**Siguiente acción**:
```bash
cd /Users/calixtosaldarriaga/development/gpt-5/turnaki-nexioq
git push origin main
```

**Resultado esperado**: Los workflows aparecerán en la pestaña Actions de GitHub.

---

### ⚠️ Paso 2: Configurar AWS OIDC (IMPORTANTE)

**Estado**: ⏳ PENDIENTE (requiere admin AWS)

**Por qué es importante**: Sin esto, los workflows no pueden autenticarse con AWS.

**Opción recomendada**: AWS OIDC (más seguro que access keys)

#### Instrucciones rápidas:

**2.1. Crear OIDC Provider**

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

**2.2. Obtener tu AWS Account ID**

```bash
aws sts get-caller-identity --query Account --output text
# Guarda este número: 123456789012
```

**2.3. Obtener tu organización/usuario de GitHub**

```bash
# Tu repo está en: https://github.com/<TU-ORG>/turnaki-nexioq
# Ejemplo: github.com/calixtosaldarriaga/turnaki-nexioq
# Entonces TU-ORG = calixtosaldarriaga
```

**2.4. Crear archivo `trust-policy.json`**

Reemplaza `TU-ACCOUNT-ID` y `TU-ORG` con tus valores:

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

**2.5. Crear el rol IAM**

```bash
aws iam create-role \
  --role-name github-actions-terraform-dev \
  --assume-role-policy-document file://trust-policy.json
```

**2.6. Adjuntar políticas necesarias**

```bash
# Política básica para Terraform
aws iam attach-role-policy \
  --role-name github-actions-terraform-dev \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

**2.7. Obtener el ARN del rol (IMPORTANTE - lo necesitas para el Paso 3)**

```bash
aws iam get-role \
  --role-name github-actions-terraform-dev \
  --query 'Role.Arn' \
  --output text

# Resultado: arn:aws:iam::123456789012:role/github-actions-terraform-dev
# ⚠️ GUARDA ESTE ARN - lo necesitas en el Paso 3
```

📚 **Documentación completa**: `.github/SECRETS_SETUP.md`

---

### ⚠️ Paso 3: Configurar Secrets en GitHub

**Estado**: ⏳ PENDIENTE (requiere admin GitHub)

**Prerequisito**: Debes haber completado el Paso 2 (OIDC)

#### Opción A: Desde GitHub UI (más fácil)

1. Ve a: **https://github.com/TU-ORG/turnaki-nexioq/settings/secrets/actions**

2. Click **"New repository secret"**

3. Agregar el secret:
   - **Name**: `AWS_ROLE_TO_ASSUME`
   - **Secret**: `arn:aws:iam::123456789012:role/github-actions-terraform-dev`
     (usa el ARN que obtuviste en el Paso 2.7)

4. Click **"Add secret"**

#### Opción B: Desde CLI (requiere GitHub CLI)

```bash
# Instalar gh CLI si no lo tienes
# brew install gh

# Autenticarte
gh auth login

# Agregar el secret
gh secret set AWS_ROLE_TO_ASSUME \
  --body "arn:aws:iam::123456789012:role/github-actions-terraform-dev"

# Verificar
gh secret list
```

**Resultado esperado**: El secret aparecerá listado (pero no podrás ver su valor por seguridad).

---

### ⚠️ Paso 4: Crear Environments en GitHub

**Estado**: ⏳ PENDIENTE (requiere admin GitHub)

**Por qué**: Los environments controlan quién puede hacer deployments a qas y prd.

#### Instrucciones:

1. **Ve a Settings → Environments** en tu repositorio:
   `https://github.com/TU-ORG/turnaki-nexioq/settings/environments`

2. **Crear environment "dev"**:
   - Click **"New environment"**
   - Name: `dev`
   - **NO agregar protecciones** (este se deploya automáticamente)
   - Click **"Configure environment"** → Save

3. **Crear environment "qas"**:
   - Click **"New environment"**
   - Name: `qas`
   - ✅ Habilitar **"Required reviewers"**
   - Agregar **1 o más personas** que deben aprobar
   - ✅ En **"Deployment branches"** seleccionar: **"Selected branches"** → `main`
   - Click **"Save protection rules"**

4. **Crear environment "prd"**:
   - Click **"New environment"**
   - Name: `prd`
   - ✅ Habilitar **"Required reviewers"**
   - Agregar **2 o más personas** que deben aprobar (ej: DevOps lead + Tech lead)
   - ✅ En **"Deployment branches"** seleccionar: **"Selected branches"** → `main`
   - (Opcional) Agregar **"Wait timer"**: 5 minutos
   - Click **"Save protection rules"**

**Resultado esperado**: 3 environments configurados con sus respectivas protecciones.

---

### 🧪 Paso 5: Primera Ejecución de Workflow

**Estado**: ⏳ PENDIENTE (después de completar pasos 1-4)

**Prerequisito**: Debes haber completado los pasos 1, 2, 3 y 4.

#### Test del workflow `terraform-plan`

**Opción A: Crear un PR de prueba**

```bash
cd /Users/calixtosaldarriaga/development/gpt-5/turnaki-nexioq

# Crear branch de test
git checkout -b test/validar-ci-cd

# Hacer un cambio mínimo en terraform
echo "# Test CI/CD - Primera validación" >> terraform/README.md

# Commit y push
git add terraform/README.md
git commit -m "test: validar workflow terraform-plan"
git push origin test/validar-ci-cd
```

Luego:
1. Ve a GitHub y crea un **Pull Request** desde `test/validar-ci-cd` → `main`
2. El workflow `terraform-plan` se ejecutará automáticamente
3. Espera 3-5 minutos
4. Verifica que:
   - ✅ El workflow pase sin errores
   - ✅ Aparezca un comentario con el plan de Terraform
   - ✅ Se vean los cambios planeados para dev, qas y prd

**Si todo se ve bien**, puedes hacer merge del PR.

**Opción B: Ejecutar manualmente**

```bash
# Requiere GitHub CLI
gh workflow run terraform-plan.yml

# Ver el progreso
gh run list --workflow=terraform-plan.yml
gh run watch
```

#### Test del workflow `terraform-apply-dev`

**Después de que `terraform-plan` funcione correctamente**:

1. Si hiciste un PR en la Opción A, hacer **merge** del PR a `main`
   - Esto disparará automáticamente `terraform-apply-dev`

2. O ejecutar manualmente:
   ```bash
   gh workflow run terraform-apply-dev.yml
   gh run watch
   ```

3. Espera 8-12 minutos

4. Verifica que:
   - ✅ Terraform apply exitoso
   - ✅ Lambdas desplegadas (8 funciones)
   - ✅ Frontend desplegado en S3
   - ✅ CloudFront invalidation ejecutada
   - ✅ Health check pasa

#### Validar el deployment

```bash
# Obtener la URL del API
cd terraform/environments/dev
terraform output api_gateway_url

# Test del health endpoint
curl https://<API-URL>/health

# Resultado esperado:
# {"status":"ok","service":"turnaki-nexioq"}
```

---

## 📋 Checklist de Validación Final

Después de completar los 5 pasos:

### Configuración
- [ ] Commit `248b1c4` pusheado a GitHub
- [ ] OIDC Provider creado en AWS
- [ ] Rol IAM `github-actions-terraform-dev` creado
- [ ] Políticas adjuntadas al rol
- [ ] Secret `AWS_ROLE_TO_ASSUME` configurado en GitHub
- [ ] Environment `dev` creado (sin protecciones)
- [ ] Environment `qas` creado (1+ reviewers)
- [ ] Environment `prd` creado (2+ reviewers)

### Workflows
- [ ] `terraform-plan` ejecutado sin errores de autenticación
- [ ] Plan de Terraform visible en comentario de PR
- [ ] `terraform-apply-dev` ejecutado exitosamente
- [ ] 8 Lambdas actualizadas en AWS
- [ ] Frontend desplegado en S3
- [ ] CloudFront invalidation completada
- [ ] Health check pasa: `GET /health` → 200

### Infraestructura
- [ ] DynamoDB table existe: `tk-nq-dev-main`
- [ ] Cognito User Pool creado
- [ ] API Gateway activo
- [ ] CloudFront distribution funcionando
- [ ] Logs en CloudWatch visibles

---

## 🆘 Troubleshooting Común

### Error: "Could not assume role"

**Solución**:
```bash
# Verificar trust policy del rol
aws iam get-role --role-name github-actions-terraform-dev

# Verificar que el "sub" coincida con tu repo
# Debe ser: "repo:TU-ORG/turnaki-nexioq:*"
```

### Error: "Backend initialization failed"

**Solución**:
```bash
# Verificar acceso al bucket S3
aws s3 ls s3://tk-nq-backups-tfstate/

# Verificar que el rol tenga políticas de S3
aws iam list-attached-role-policies \
  --role-name github-actions-terraform-dev
```

### Workflow no se ejecuta

**Solución**:
- Verifica que pusheaste el commit a GitHub
- Verifica que los archivos `.yml` estén en `.github/workflows/`
- Revisa la pestaña "Actions" → Si hay errores, revisa los logs

---

## 📚 Documentación de Referencia

- **Plan completo en inglés**: `.github/SIGUIENTES_PASOS.md`
- **Configuración de secrets**: `.github/SECRETS_SETUP.md`
- **Documentación de workflows**: `.github/workflows/README.md`
- **Reporte Fase 6**: `terraform/FASE6_COMPLETADA.md`
- **Validación completa**: `VALIDACION_FASES_1-6.md`

---

## 🎯 Resumen Visual del Proceso

```
Paso 1: git push origin main
   ↓
Paso 2: Crear OIDC Provider + Rol IAM en AWS
   ↓
Paso 3: Agregar secret AWS_ROLE_TO_ASSUME en GitHub
   ↓
Paso 4: Crear environments (dev, qas, prd) en GitHub
   ↓
Paso 5: Crear PR de prueba → terraform-plan se ejecuta
   ↓
Merge PR → terraform-apply-dev se ejecuta automáticamente
   ↓
✅ Dev desplegado con CI/CD funcionando
```

---

## ✨ Estado Final Esperado

```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║        ✅ CI/CD COMPLETAMENTE FUNCIONAL                      ║
║                                                               ║
║   🔄  Auto-deploy en dev desde main                          ║
║   🔐  Deployments controlados en qas y prd                   ║
║   📊  Health checks automáticos                              ║
║   🚀  Tiempo de deployment: -60%                             ║
║   📝  Comentarios automáticos en PRs                         ║
║                                                               ║
║        🎉 PROYECTO 100% OPERATIVO                            ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## 📞 ¿Necesitas Ayuda?

Si tienes problemas con algún paso:

1. **Revisa la documentación detallada** en `.github/SECRETS_SETUP.md`
2. **Revisa los logs del workflow** en GitHub Actions
3. **Verifica los prerequisitos** de cada paso
4. **Contacta al equipo de DevOps**

---

**Creado**: 6 de Octubre 2025  
**Autor**: DevOps Team Turnaki-NexioQ  
**Versión**: 1.0.0  
**Siguiente milestone**: Activación de CI/CD

---

**🚀 ¡Éxito con la activación del CI/CD!**
