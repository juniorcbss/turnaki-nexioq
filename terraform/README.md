# 🏗️ Infraestructura Terraform - Turnaki-NexioQ

**Infraestructura como Código (IaC) para el Sistema SaaS Multi-Tenant de Reservas Odontológicas**

[![Terraform](https://img.shields.io/badge/Terraform-1.9+-844FBA?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![Fase 2](https://img.shields.io/badge/Fase%202-Completada-success)](./FASE2_COMPLETADA.md)

---

## 📋 Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Módulos Disponibles](#módulos-disponibles)
4. [Quick Start](#quick-start)
5. [Ambientes](#ambientes)
6. [Scripts Útiles](#scripts-útiles)
7. [Convenciones](#convenciones)
8. [Estado de Migración](#estado-de-migración)

---

## 🎯 Descripción General

Este directorio contiene toda la infraestructura del proyecto Turnaki-NexioQ implementada con **Terraform**, siguiendo las mejores prácticas de Infrastructure as Code (IaC).

### Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                    CloudFront CDN                       │
│                  (Frontend Global)                      │
└──────────────────┬──────────────────────────────────────┘
                   │
         ┌─────────┴─────────┐
         │                   │
┌────────▼────────┐  ┌──────▼───────┐
│   S3 Bucket     │  │  WAF Rules   │
│   (Frontend)    │  │  (Security)  │
└─────────────────┘  └──────────────┘

┌─────────────────────────────────────────────────────────┐
│              API Gateway HTTP API                       │
│           (JWT Auth + Rate Limiting)                    │
└──────────────────┬──────────────────────────────────────┘
                   │
         ┌─────────┴─────────┐
         │                   │
┌────────▼────────┐  ┌──────▼───────────┐
│  Lambda Rust    │  │  Cognito Pool    │
│  (8 Functions)  │  │  (Auth)          │
└────────┬────────┘  └──────────────────┘
         │
┌────────▼────────────────────────────────┐
│         DynamoDB Table                  │
│      (Single-Table Design)              │
└─────────────────────────────────────────┘
```

### Tecnologías

- **IaC**: Terraform 1.9+
- **Cloud**: AWS
- **Backend**: Rust + Lambda (ARM64)
- **Database**: DynamoDB (single-table)
- **Auth**: Cognito User Pool + JWT
- **CDN**: CloudFront + S3
- **Security**: WAF + X-Ray
- **Monitoring**: CloudWatch + SNS

---

## 📁 Estructura del Proyecto

```
terraform/
│
├── modules/                         # 🧩 Módulos reutilizables
│   ├── iam/                        # Roles y políticas IAM
│   ├── dynamodb/                   # Tabla principal con GSIs
│   ├── cognito/                    # User Pool + Client
│   ├── lambda/                     # Función Lambda genérica
│   ├── api-gateway/                # HTTP API + Authorizer
│   ├── s3-cloudfront/              # Hosting frontend
│   ├── waf/                        # Web Application Firewall
│   ├── cloudwatch/                 # Dashboard + Alarmas
│   └── ses/                        # Email transaccional
│
├── environments/                    # 🌍 Configuraciones por ambiente
│   ├── dev/
│   │   ├── main.tf                 # Orquestador de módulos
│   │   ├── variables.tf
│   │   ├── terraform.tfvars        # Valores específicos dev
│   │   ├── backend.tf              # S3 backend config
│   │   └── outputs.tf
│   ├── qas/
│   │   └── ...
│   └── prd/
│       └── ...
│
├── scripts/                         # 🔧 Scripts operativos
│   ├── validate-modules.sh         # Validar módulos
│   ├── init-backend.sh             # Crear S3 + DynamoDB para tfstate
│   ├── plan-all.sh                 # Plan en todos los ambientes
│   ├── apply-dev.sh                # Deploy dev
│   ├── apply-qas.sh                # Deploy qas
│   ├── apply-prd.sh                # Deploy prd
│   ├── destroy-dev.sh              # Destruir dev
│   └── format-all.sh               # Formatear código
│
├── .gitignore
├── README.md                        # 📚 Este archivo
├── FASE2_COMPLETADA.md             # Estado Fase 2
└── PLAN_MIGRACION_TERRAFORM.md     # Plan maestro
```

---

## 🧩 Módulos Disponibles

### Módulos de Infraestructura

| Módulo | Propósito | Estado | Documentación |
|--------|-----------|--------|---------------|
| **iam** | Roles IAM para Lambda | ✅ | [README](modules/iam/README.md) |
| **dynamodb** | Tabla single-table + GSIs | ✅ | [README](modules/dynamodb/README.md) |
| **cognito** | User Pool + OAuth | ✅ | [README](modules/cognito/README.md) |
| **lambda** | Función Lambda Rust | ✅ | [README](modules/lambda/README.md) |
| **api-gateway** | HTTP API + JWT Auth | ✅ | [README](modules/api-gateway/README.md) |
| **s3-cloudfront** | Frontend hosting + CDN | ✅ | [README](modules/s3-cloudfront/README.md) |
| **waf** | Web Application Firewall | ✅ | [README](modules/waf/README.md) |
| **cloudwatch** | Observabilidad + Alarmas | ✅ | [README](modules/cloudwatch/README.md) |
| **ses** | Email transaccional | ✅ | [README](modules/ses/README.md) |

**Estado**: 9/9 módulos completados ✅

### Características de los Módulos

- ✅ **Reutilizables** entre ambientes (dev/qas/prd)
- ✅ **Documentados** con README completo
- ✅ **Validados** automáticamente
- ✅ **Tipados** con variables y outputs claros
- ✅ **Ejemplos** de uso incluidos
- ✅ **Costos** estimados por módulo

---

## 🚀 Quick Start

### Prerrequisitos

```bash
# Terraform
terraform --version  # >= 1.9.0

# AWS CLI
aws --version  # >= 2.0

# Configurar credenciales
aws configure
```

### 1. Validar Módulos

```bash
cd terraform
./scripts/validate-modules.sh

# Output esperado:
# ✅ Todos los módulos son válidos!
# Tasa de éxito: 100.00%
```

### 2. Inicializar Backend (Primera vez)

```bash
./scripts/init-backend.sh
# Crea bucket S3 y tabla DynamoDB para tfstate
```

### 3. Deploy Ambiente Dev

```bash
cd environments/dev

# Inicializar
terraform init

# Ver plan
terraform plan

# Aplicar cambios
terraform apply
```

### 4. Verificar Deployment

```bash
# Obtener outputs
terraform output

# Ejemplo:
# api_endpoint = "https://abc123.execute-api.us-east-1.amazonaws.com"
# frontend_url = "https://d1234abcd.cloudfront.net"
```

---

## 🌍 Ambientes

### Estructura Multi-Ambiente

| Ambiente | Propósito | Estado | URL |
|----------|-----------|--------|-----|
| **dev** | Desarrollo y testing | 🚧 En progreso | `dev.turnaki.nexioq.com` |
| **qas** | Pre-producción | ⏸️ Pendiente | `qas.turnaki.nexioq.com` |
| **prd** | Producción | ⏸️ Pendiente | `turnaki.nexioq.com` |

### Diferencias por Ambiente

| Característica | Dev | QAS | PRD |
|----------------|-----|-----|-----|
| Lambda Memory | 512 MB | 1024 MB | 1024 MB |
| DynamoDB Mode | PAY_PER_REQUEST | PAY_PER_REQUEST | PROVISIONED |
| CloudWatch Logs | 7 días | 14 días | 90 días |
| Point-in-Time Recovery | ❌ | ✅ | ✅ |
| WAF | Básico | Completo | Completo |
| Alarmas | ❌ | ✅ | ✅ |
| CloudFront Price Class | 100 | 200 | All |

---

## 🔧 Scripts Útiles

### Validación y Formato

```bash
# Validar todos los módulos
./scripts/validate-modules.sh

# Formatear código Terraform
./scripts/format-all.sh

# Validar sintaxis
cd environments/dev
terraform validate
```

### Deployment

```bash
# Plan en todos los ambientes
./scripts/plan-all.sh

# Deploy específico
./scripts/apply-dev.sh
./scripts/apply-qas.sh
./scripts/apply-prd.sh

# Destruir (solo dev)
./scripts/destroy-dev.sh
```

### State Management

```bash
# Ver estado actual
terraform state list

# Mostrar recurso específico
terraform state show aws_lambda_function.bookings

# Importar recurso existente
terraform import module.dynamodb.aws_dynamodb_table.main turnaki-nexioq-dev-main
```

---

## 📝 Convenciones

### Nombres de Recursos

```hcl
{project_name}-{environment}-{resource_type}-{name}
```

**Ejemplos**:
- Lambda: `turnaki-nexioq-dev-lambda-bookings`
- DynamoDB: `turnaki-nexioq-dev-main`
- S3: `turnaki-nexioq-dev-frontend`

### Variables

```hcl
variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Solo minúsculas, números y guiones"
  }
}
```

### Tags

```hcl
tags = {
  Project     = "Turnaki-NexioQ"
  Environment = var.environment
  ManagedBy   = "Terraform"
  Owner       = "DevOps"
}
```

---

## 📊 Estado de Migración

### Fase Actual

**Fase 2: Módulos Base** ✅ **COMPLETADA** (100%)

- [x] 9 módulos implementados
- [x] Documentación completa
- [x] Script de validación
- [x] Ejemplos de uso
- [x] Testing exitoso

Ver: [FASE2_COMPLETADA.md](./FASE2_COMPLETADA.md)

### Roadmap

```
Fase 1: Preparación          ✅ Completada
Fase 2: Módulos Base          ✅ Completada
Fase 3: Ambiente Dev          🚧 En progreso
Fase 4: Ambientes QAS y PRD   ⏸️ Pendiente
Fase 5: Limpieza CDK          ⏸️ Pendiente
Fase 6: CI/CD                 ⏸️ Pendiente
```

Ver: [PLAN_MIGRACION_TERRAFORM.md](../PLAN_MIGRACION_TERRAFORM.md)

---

## 📚 Documentación Adicional

### Por Módulo

- [IAM](modules/iam/README.md) - Roles y políticas
- [DynamoDB](modules/dynamodb/README.md) - Base de datos
- [Cognito](modules/cognito/README.md) - Autenticación
- [Lambda](modules/lambda/README.md) - Funciones serverless
- [API Gateway](modules/api-gateway/README.md) - API HTTP
- [S3 + CloudFront](modules/s3-cloudfront/README.md) - Frontend
- [WAF](modules/waf/README.md) - Seguridad
- [CloudWatch](modules/cloudwatch/README.md) - Observabilidad
- [SES](modules/ses/README.md) - Emails

### General

- [Plan de Migración](../PLAN_MIGRACION_TERRAFORM.md) - Estrategia completa
- [Estado Fase 2](./FASE2_COMPLETADA.md) - Progreso actual

---

## 💰 Costos Estimados

### Por Ambiente Dev

| Servicio | Costo Mensual |
|----------|---------------|
| Lambda (8 funciones) | ~$1.00 |
| DynamoDB (PAY_PER_REQUEST) | ~$2.00 |
| API Gateway | ~$1.50 |
| S3 + CloudFront | ~$5.00 |
| Cognito | Gratis (< 50K MAU) |
| WAF | ~$32.00 |
| CloudWatch | ~$11.50 |
| SES | ~$0.50 |
| **Total** | **~$53.50/mes** |

### Optimizaciones

- Lambda ARM64: -20% costo
- DynamoDB on-demand: Solo pagas lo que usas
- CloudFront PriceClass_100: Regiones limitadas
- CloudWatch logs: 7 días retención

---

## 🔒 Seguridad

### Buenas Prácticas Implementadas

- ✅ **Secrets**: No hay credenciales hardcoded
- ✅ **IAM**: Principio de mínimo privilegio
- ✅ **Encriptación**: At-rest y in-transit
- ✅ **WAF**: Protección contra OWASP Top 10
- ✅ **HTTPS**: Obligatorio en todas partes
- ✅ **X-Ray**: Tracing habilitado
- ✅ **CloudWatch**: Logs y métricas

### Recomendaciones PRD

```hcl
# Habilitar en producción:
enable_point_in_time_recovery = true
enable_alarms                  = true
log_retention_days             = 90
enable_waf                     = true
```

---

## 🐛 Troubleshooting

### Error: Backend not initialized

```bash
cd environments/dev
terraform init
```

### Error: Module not found

```bash
# Verificar que estés en el directorio correcto
pwd  # Debe ser .../terraform/environments/{env}

# Verificar módulos
ls ../../modules/
```

### Error: Invalid provider configuration

```bash
# Verificar credenciales AWS
aws sts get-caller-identity

# Reconfigurar si es necesario
aws configure
```

### State Lock Error

```bash
# Listar locks activos
aws dynamodb scan --table-name terraform-state-lock

# Forzar unlock (usar con cuidado)
terraform force-unlock LOCK_ID
```

---

## 🤝 Contribuir

### Agregar Nuevo Módulo

1. Crear directorio en `modules/`
2. Crear archivos requeridos:
   - `main.tf`
   - `variables.tf`
   - `outputs.tf`
   - `README.md`
3. Validar: `./scripts/validate-modules.sh`
4. Documentar en este README

### Modificar Módulo Existente

1. Editar archivos del módulo
2. Formatear: `terraform fmt -recursive`
3. Validar: `terraform validate`
4. Probar en dev: `terraform plan`
5. Actualizar README del módulo

---

## 📞 Soporte

### Documentación

- 📚 [Terraform Docs](https://www.terraform.io/docs)
- 📚 [AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- 📚 [Best Practices](https://www.terraform-best-practices.com/)

### Issues

- 🐛 [GitHub Issues](https://github.com/turnaki-nexioq/issues)
- 📧 Email: devops@turnaki.com

---

## 📄 Licencia

MIT License - Ver archivo LICENSE en la raíz del proyecto

---

**Última actualización**: 6 de Octubre 2025  
**Versión**: 1.0.0  
**Mantenido por**: Equipo DevOps Turnaki-NexioQ