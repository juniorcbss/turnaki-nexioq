# 🔄 Diferencias Entre Ambientes

**Proyecto**: Turnaki-NexioQ  
**Fecha**: 6 de Octubre 2025  
**Versión**: 1.0.0

---

## 📋 Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Configuración por Ambiente](#configuración-por-ambiente)
3. [Diferencias Detalladas](#diferencias-detalladas)
4. [Costos Estimados](#costos-estimados)
5. [Guía de Despliegue](#guía-de-despliegue)
6. [Consideraciones de Seguridad](#consideraciones-de-seguridad)

---

## 📊 Resumen Ejecutivo

Este documento detalla las diferencias de configuración entre los tres ambientes de Turnaki-NexioQ:

| Ambiente | Propósito | Estado | Criticidad |
|----------|-----------|--------|------------|
| **DEV** | Desarrollo y pruebas locales | ✅ Activo | Baja |
| **QAS** | Testing, QA y staging | 🚧 Listo para deploy | Media |
| **PRD** | Producción | ⏸️ Pendiente | Alta |

---

## 🏗️ Configuración por Ambiente

### 🔵 DEV (Desarrollo)

**Propósito**: Ambiente de desarrollo para pruebas rápidas y experimentación.

**Características**:
- ⚡ Configuración mínima para desarrollo rápido
- 🔓 Acceso desde localhost
- 💵 Costos optimizados
- 📝 Logs básicos (7 días)
- ⚠️ Sin alarmas críticas

**URLs**:
```
Frontend: http://localhost:5173
API:      (generado por API Gateway)
Cognito:  turnaki-nexioq-dev-auth.auth.us-east-1.amazoncognito.com
```

### 🟡 QAS (Quality Assurance)

**Propósito**: Ambiente de QA para pruebas de integración y aceptación.

**Características**:
- 🧪 Configuración para testing exhaustivo
- 🌐 URLs públicas de staging
- 📊 Alarmas opcionales
- 📝 Logs extendidos (14 días)
- 🔍 Log level DEBUG para troubleshooting
- ⚡ Mayor capacidad de throttling para load testing
- 💾 Point-in-time recovery habilitado
- 🔄 Versionado de S3 habilitado

**URLs**:
```
Frontend: https://qas.turnaki.nexioq.com
API:      (generado por API Gateway)
Cognito:  turnaki-nexioq-qas-auth.auth.us-east-1.amazoncognito.com
```

### 🔴 PRD (Producción)

**Propósito**: Ambiente de producción para usuarios finales.

**Características**:
- 🚀 Configuración optimizada para producción
- 🌍 Distribución global de CloudFront
- 🔔 Alarmas críticas OBLIGATORIAS
- 📝 Logs extendidos (30 días)
- ⚠️ Log level WARN (solo errores/warnings)
- 💪 Mayor memoria en Lambdas (1024 MB)
- 🔒 Alta seguridad y compliance
- 💾 Point-in-time recovery OBLIGATORIO
- 🔄 Versionado de S3 OBLIGATORIO
- ⚡ Alta capacidad de throttling

**URLs**:
```
Frontend: https://turnaki.nexioq.com
API:      (generado por API Gateway)
Cognito:  turnaki-nexioq-prd-auth.auth.us-east-1.amazoncognito.com
```

---

## 🔍 Diferencias Detalladas

### 1. DynamoDB

| Parámetro | DEV | QAS | PRD |
|-----------|-----|-----|-----|
| **Billing Mode** | PAY_PER_REQUEST | PAY_PER_REQUEST | PAY_PER_REQUEST |
| **Point-in-Time Recovery** | ❌ Deshabilitado | ✅ Habilitado | ✅ **OBLIGATORIO** |
| **Encryption** | ✅ Default | ✅ Default | ✅ Default |
| **Backup** | Manual | Manual | Automático recomendado |

**Justificación PRD**: El point-in-time recovery permite restaurar la base de datos a cualquier punto en los últimos 35 días, crítico para compliance y disaster recovery.

---

### 2. Lambda Functions

| Parámetro | DEV | QAS | PRD |
|-----------|-----|-----|-----|
| **Memory Size** | 256-512 MB | 512 MB | **1024 MB** |
| **Timeout** | 10-30s | 30s | 30s |
| **Log Level** | `info` | `debug` | `warn` |
| **Log Retention** | 7 días | 14 días | **30 días** |
| **X-Ray Tracing** | ✅ Activo | ✅ Activo | ✅ Activo |

**Justificación PRD**: 
- Mayor memoria = mejor performance y menor cold start
- Log level `warn` reduce costos y ruido en logs
- 30 días de retención para auditorías

---

### 3. API Gateway

| Parámetro | DEV | QAS | PRD |
|-----------|-----|-----|-----|
| **Throttle Burst** | 100 req/s | 200 req/s | **500 req/s** |
| **Throttle Rate** | 50 req/s | 100 req/s | **250 req/s** |
| **Log Retention** | 7 días | 14 días | **30 días** |
| **CORS Origins** | localhost | staging URL | production URL |

**Justificación PRD**: Mayor capacidad para manejar picos de tráfico en producción.

---

### 4. Cognito

| Parámetro | DEV | QAS | PRD |
|-----------|-----|-----|-----|
| **User Pool** | Separado | Separado | Separado |
| **Domain** | dev-auth | qas-auth | prd-auth |
| **Password Policy** | Estándar | Estándar | Estándar |
| **MFA** | Opcional | Opcional | **Recomendado** |

**Nota**: Cada ambiente tiene su propio User Pool para aislamiento completo.

---

### 5. Frontend (S3 + CloudFront)

| Parámetro | DEV | QAS | PRD |
|-----------|-----|-----|-----|
| **S3 Versioning** | ❌ Deshabilitado | ✅ Habilitado | ✅ **OBLIGATORIO** |
| **CloudFront Price Class** | PriceClass_100 | PriceClass_100 | **PriceClass_All** |
| **Distribution** | NA-EU | NA-EU | **Global** |
| **Cache TTL** | 1 hora | 1 hora | 24 horas |

**Justificación PRD**: 
- PriceClass_All = distribución global para mejor latencia
- Versionado para rollback rápido

---

### 6. WAF

| Parámetro | DEV | QAS | PRD |
|-----------|-----|-----|-----|
| **Rate Limit** | 2000 req/5min | 3000 req/5min | **2000 req/5min** |
| **Scope** | REGIONAL | REGIONAL | REGIONAL |
| **Managed Rules** | Basic | Basic | Basic |

**Nota**: QAS tiene mayor límite para permitir load testing sin bloqueos.

---

### 7. CloudWatch

| Parámetro | DEV | QAS | PRD |
|-----------|-----|-----|-----|
| **Dashboard** | ✅ Básico | ✅ Completo | ✅ Completo |
| **Alarmas** | ❌ Deshabilitadas | ✅ Opcionales | ✅ **OBLIGATORIAS** |
| **Email Alarmas** | No | Opcional | **Requerido** |
| **Lambda Error Threshold** | 10 | 20 | **5** |
| **API 5xx Threshold** | 10 | 20 | **5** |

**Justificación PRD**: Baja tolerancia a errores en producción con notificaciones inmediatas.

---

### 8. SES (Email)

| Parámetro | DEV | QAS | PRD |
|-----------|-----|-----|-----|
| **Email Identity** | Opcional | Opcional | **Requerido** |
| **Domain Identity** | Opcional | Opcional | **Recomendado** |
| **Configuration Set** | Básico | Básico | Con tracking |
| **Sandbox Mode** | ✅ | ✅ | ❌ **Production** |

**Nota**: En PRD se debe solicitar salida del sandbox de SES.

---

## 💰 Costos Estimados

### Costo Mensual por Ambiente

| Servicio | DEV | QAS | PRD | Notas |
|----------|-----|-----|-----|-------|
| **Lambda** | $5-10 | $10-20 | $50-100 | Basado en 1M invocaciones |
| **DynamoDB** | $5-10 | $10-15 | $30-50 | PAY_PER_REQUEST |
| **API Gateway** | $3-5 | $5-10 | $15-30 | Basado en 1M requests |
| **CloudFront** | $1-3 | $5-10 | $20-50 | Según tráfico |
| **S3** | $1-2 | $2-5 | $5-10 | Con versionado |
| **Cognito** | $0-5 | $5-10 | $10-30 | Basado en MAU |
| **CloudWatch** | $2-5 | $5-10 | $10-20 | Logs + métricas |
| **WAF** | $5 | $5 | $5-10 | Base + rules |
| **State (S3+DynamoDB)** | $2 | $2 | $2 | Terraform state |
| **TOTAL** | **$24-47** | **$49-97** | **$147-302** |

**Factores que impactan costos**:
- Número de usuarios activos mensuales (MAU)
- Volumen de requests
- Tráfico de CloudFront
- Retención de logs

---

## 🚀 Guía de Despliegue

### Orden de Deployment Recomendado

```bash
# 1. DEV (ya desplegado)
cd terraform/environments/dev
terraform init
terraform plan
terraform apply

# 2. QAS (después de validar DEV)
cd ../qas
terraform init
terraform plan
terraform apply

# 3. Validar QAS completamente antes de PRD
# - Ejecutar todos los tests E2E
# - Validar performance
# - Validar seguridad

# 4. PRD (solo después de QAS exitoso)
cd ../prd
terraform init
terraform plan  # ⚠️ REVISAR CUIDADOSAMENTE
terraform apply -auto-approve=false  # ⚠️ Confirmación manual
```

### Comandos de Validación

```bash
# Validar sintaxis
terraform fmt -check -recursive

# Validar configuración
cd environments/qas
terraform validate

cd ../prd
terraform validate

# Plan sin aplicar
terraform plan -out=plan.tfplan

# Ver plan detallado
terraform show plan.tfplan
```

---

## 🔒 Consideraciones de Seguridad

### Por Ambiente

#### DEV
- ✅ Acceso desde localhost
- ✅ Cognito con políticas básicas
- ⚠️ Sin cifrado adicional requerido
- ⚠️ Secrets en variables de entorno

#### QAS
- ✅ Acceso HTTPS únicamente
- ✅ Cognito con políticas estándar
- ✅ Cifrado en tránsito
- ⚠️ Secrets en variables de entorno
- ✅ WAF habilitado

#### PRD
- ✅ Acceso HTTPS únicamente
- ✅ Cognito con políticas robustas
- ✅ MFA recomendado para admins
- ✅ Cifrado en tránsito y reposo
- ✅ Secrets en AWS Secrets Manager (recomendado)
- ✅ WAF habilitado con reglas estrictas
- ✅ CloudTrail habilitado (recomendado)
- ✅ GuardDuty habilitado (recomendado)

---

## 🔄 Flujo de Promoción

```
┌─────────┐         ┌─────────┐         ┌─────────┐
│   DEV   │  ────▶  │   QAS   │  ────▶  │   PRD   │
│         │         │         │         │         │
│ Develop │         │  Test   │         │  Live   │
│  & Test │         │ & Validate │       │ Users   │
└─────────┘         └─────────┘         └─────────┘
     ▲                   ▲                   ▲
     │                   │                   │
     │                   │                   │
  Quick            Thorough            Monitored
  Iteration         Testing            24/7
```

**Reglas**:
1. ✅ Todo cambio debe pasar por DEV primero
2. ✅ QAS debe estar estable antes de promover a PRD
3. ✅ PRD solo se actualiza en ventanas de mantenimiento
4. ✅ Rollback debe estar siempre disponible

---

## 📝 Variables de Entorno por Ambiente

### DEV
```hcl
aws_region   = "us-east-1"
project_name = "turnaki-nexioq"
environment  = "dev"

cognito_callback_urls = ["http://localhost:5173", "http://localhost:5173/callback"]
cors_allowed_origins  = ["http://localhost:5173", "http://127.0.0.1:5173"]
```

### QAS
```hcl
aws_region   = "us-east-1"
project_name = "turnaki-nexioq"
environment  = "qas"

cognito_callback_urls = ["https://qas.turnaki.nexioq.com", "https://qas.turnaki.nexioq.com/callback"]
cors_allowed_origins  = ["https://qas.turnaki.nexioq.com"]
alarm_email           = null  # Opcional
```

### PRD
```hcl
aws_region   = "us-east-1"
project_name = "turnaki-nexioq"
environment  = "prd"

cognito_callback_urls = ["https://turnaki.nexioq.com", "https://turnaki.nexioq.com/callback"]
cors_allowed_origins  = ["https://turnaki.nexioq.com"]
alarm_email           = "alerts@turnaki.com"  # ⚠️ OBLIGATORIO
```

---

## 📊 Matriz de Compliance

| Requisito | DEV | QAS | PRD |
|-----------|-----|-----|-----|
| **HTTPS Only** | ❌ | ✅ | ✅ |
| **Encryption at Rest** | ✅ | ✅ | ✅ |
| **Encryption in Transit** | ⚠️ | ✅ | ✅ |
| **Backups** | ❌ | ✅ | ✅ |
| **Monitoring** | ⚠️ | ✅ | ✅ |
| **Alerting** | ❌ | ⚠️ | ✅ |
| **Audit Logs** | ⚠️ | ✅ | ✅ |
| **WAF** | ✅ | ✅ | ✅ |
| **DDoS Protection** | ⚠️ | ✅ | ✅ |

---

## 🎯 Checklist Pre-Producción

Antes de desplegar a PRD, verificar:

- [ ] ✅ Todos los tests E2E pasan en QAS
- [ ] ✅ Performance testing completado
- [ ] ✅ Security scan sin vulnerabilidades críticas
- [ ] ✅ Alarmas configuradas y probadas
- [ ] ✅ Email de alarmas verificado
- [ ] ✅ SES fuera del sandbox
- [ ] ✅ Dominios DNS configurados
- [ ] ✅ Certificados SSL configurados
- [ ] ✅ Plan de rollback documentado
- [ ] ✅ Runbook actualizado
- [ ] ✅ Equipo de soporte notificado
- [ ] ✅ Ventana de mantenimiento programada

---

## 📞 Contacto

Para dudas sobre ambientes:
- 📧 **DevOps**: devops@turnaki.com
- 📚 **Docs**: `/terraform/README.md`
- 🐛 **Issues**: GitHub Issues

---

**Documento creado**: 6 de Octubre 2025  
**Última actualización**: 6 de Octubre 2025  
**Versión**: 1.0.0  
**Autor**: Equipo DevOps Turnaki-NexioQ
