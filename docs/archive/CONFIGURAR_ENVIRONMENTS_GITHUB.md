# 🛡️ Configurar Environments en GitHub

**Repositorio**: https://github.com/juniorcbss/turnaki-nexioq  
**Estado**: ⚠️ PENDIENTE - Requiere configuración manual

---

## 📋 Environments Necesarios

Los workflows de CI/CD necesitan que configures **3 environments** en GitHub con sus respectivas protecciones:

1. **dev** - Sin protecciones (auto-deploy)
2. **qas** - Con 1+ reviewer requerido
3. **prd** - Con 2+ reviewers requeridos

---

## 🔧 Instrucciones Paso a Paso

### 1. Acceder a Configuración de Environments

Ve a: **https://github.com/juniorcbss/turnaki-nexioq/settings/environments**

(Settings → Environments)

### 2. Crear Environment "dev"

1. Click **"New environment"**
2. **Name**: `dev`
3. **NO agregar protecciones** (este ambiente se deploya automáticamente desde main)
4. Click **"Configure environment"**
5. Click **"Save protection rules"**

✅ **Resultado**: Environment `dev` sin protecciones

### 3. Crear Environment "qas"

1. Click **"New environment"**
2. **Name**: `qas`
3. ✅ **Habilitar "Required reviewers"**
   - Click en la checkbox ✅
   - **Agregar al menos 1 persona** que debe aprobar deployments a QAS
   - Ejemplo: tu propio usuario o miembros del equipo DevOps
4. ✅ **Deployment branches**: 
   - Seleccionar **"Selected branches"**
   - Agregar `main`
5. Click **"Save protection rules"**

✅ **Resultado**: Environment `qas` con 1+ reviewer requerido

### 4. Crear Environment "prd"

1. Click **"New environment"**
2. **Name**: `prd`
3. ✅ **Habilitar "Required reviewers"**
   - Click en la checkbox ✅
   - **Agregar al menos 2 personas** (recomendado: DevOps lead + Tech lead)
   - Ejemplo: tú + otro miembro del equipo
4. ✅ **Deployment branches**: 
   - Seleccionar **"Selected branches"**
   - Agregar `main`
5. (Opcional) ✅ **Wait timer**: 
   - Agregar 5 minutos de espera antes del deployment
6. Click **"Save protection rules"**

✅ **Resultado**: Environment `prd` con 2+ reviewers requeridos, solo desde main

---

## 📊 Configuración Final Esperada

Después de completar los pasos, deberías tener:

```
Environments:
├── dev      (sin protecciones)
├── qas      (1+ reviewers, main only)  
└── prd      (2+ reviewers, main only, wait timer opcional)
```

---

## 🧪 Validar Configuración

### Método 1: Via GitHub UI

Ve a: **https://github.com/juniorcbss/turnaki-nexioq/settings/environments**

Verifica que aparezcan los 3 environments listados con sus respectivas protecciones.

### Método 2: Ejecutar Workflow Manual

```bash
# Después de configurar environments, probar:
gh workflow run terraform-apply-qas.yml -f confirm=yes

# Debería:
# 1. Requerir approval (por los reviewers configurados)
# 2. Solo permitir ejecución desde branch main
```

---

## ⚠️ Importante

### Reviewers Recomendados

Para **qas**:
- Tu usuario principal
- O cualquier miembro del equipo DevOps

Para **prd**:
- DevOps lead (tú)
- Tech lead o desarrollador senior
- Mínimo 2 personas diferentes

### Branch Protection

Los environments `qas` y `prd` **SOLO** deben permitir deployments desde `main`. Esto garantiza que:
- No se puedan hacer deployments desde feature branches
- El código pase por el proceso de review (PR)
- Se mantenga la integridad de los ambientes críticos

---

## 🚀 Después de Configurar

Una vez configurados los environments, podrás:

### Deploy Automático a Dev
- Cada push a `main` disparará automáticamente `terraform-apply-dev`
- No requiere aprobación manual

### Deploy Manual a QAS
```bash
gh workflow run terraform-apply-qas.yml -f confirm=yes
# → Requiere aprobación de 1+ reviewers
# → Solo desde branch main
```

### Deploy Manual a Producción
```bash
gh workflow run terraform-apply-prd.yml -f confirm=yes  
# → Requiere aprobación de 2+ reviewers
# → Solo desde branch main
# → Wait timer opcional (5 min)
```

---

## 📚 Documentación de Referencia

- [GitHub Environments Docs](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Required Reviewers](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#required-reviewers)
- [Deployment Branches](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#deployment-branches)

---

## ✅ Checklist de Validación

Después de configurar, marca:

- [ ] Environment `dev` creado (sin protecciones)
- [ ] Environment `qas` creado (1+ reviewers, main only)
- [ ] Environment `prd` creado (2+ reviewers, main only)
- [ ] Reviewers agregados en qas y prd
- [ ] Branch restriction en `main` para qas y prd
- [ ] Probado workflow manual en qas (con approval)

---

## 🎯 Estado Después de Configurar

```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║        ✅ CI/CD COMPLETAMENTE FUNCIONAL                      ║
║                                                               ║
║   🔄  Auto-deploy: dev desde main                            ║
║   🛡️  Deployments controlados: qas (1+ reviewer)            ║
║   🔒  Deployments seguros: prd (2+ reviewers)                ║
║   🚀  Workflows listos para usar                             ║
║                                                               ║
║        🎉 PROYECTO 100% OPERATIVO                            ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

**🔗 Link directo**: https://github.com/juniorcbss/turnaki-nexioq/settings/environments

**⏱️ Tiempo estimado**: 10-15 minutos

**👥 Requiere**: Admin access al repositorio
