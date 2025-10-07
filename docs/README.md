# 📚 Documentación - Turnaki-NexioQ

Esta carpeta contiene toda la documentación técnica, organizacional y de proceso del proyecto.

## 📋 Índice de Documentación

### 🚀 Documentación Principal

| Documento | Descripción |
|-----------|-------------|
| **[API.md](API.md)** | Especificación completa de endpoints |
| **[AUTHENTICATION.md](AUTHENTICATION.md)** | Flujo OAuth 2.0 con Cognito |
| **[DEVELOPMENT.md](DEVELOPMENT.md)** | Setup y desarrollo local |
| **[RUNBOOK.md](RUNBOOK.md)** | Operaciones y troubleshooting |
| **[ROADMAP.md](ROADMAP.md)** | Mejoras propuestas |
| **[TESTING.md](TESTING.md)** | E2E y unit testing |

### 🏗️ Infraestructura

| Documento | Descripción |
|-----------|-------------|
| **[infrastructure/ARCHITECTURE.md](infrastructure/ARCHITECTURE.md)** | Diseño técnico y diagramas |

### 🚀 Deployment

| Documento | Descripción |
|-----------|-------------|
| **[deployment/DEPLOYMENT.md](deployment/DEPLOYMENT.md)** | Guía de deployment con Terraform |

### ⚙️ Setup Inicial

| Documento | Descripción |
|-----------|-------------|
| **[setup/ONBOARDING_CHECKLIST.md](setup/ONBOARDING_CHECKLIST.md)** | Checklist de configuración inicial |

### 📦 Histórico y Estados

La carpeta **[archive/](archive/)** contiene documentos históricos del desarrollo:

- Estados de completitud por fases del proyecto
- Guías de configuración específicas 
- Análisis de gaps y retrospectivas
- Documentos de sprints completados

## 🗂️ Organización por Tema

### Backend (Rust + Lambda)
- [API.md](API.md) - Endpoints y especificación
- [infrastructure/ARCHITECTURE.md](infrastructure/ARCHITECTURE.md) - Arquitectura serverless

### Frontend (Svelte)
- [DEVELOPMENT.md](DEVELOPMENT.md) - Setup local
- [TESTING.md](TESTING.md) - Tests E2E

### Infraestructura (Terraform)
- [deployment/DEPLOYMENT.md](deployment/DEPLOYMENT.md) - Proceso de deployment
- [infrastructure/ARCHITECTURE.md](infrastructure/ARCHITECTURE.md) - Módulos y recursos

### Operaciones
- [RUNBOOK.md](RUNBOOK.md) - Troubleshooting y monitoreo
- [AUTHENTICATION.md](AUTHENTICATION.md) - Gestión de usuarios

## 📝 Convenciones

- **Formato**: Todos los documentos usan Markdown con emojis para mejor legibilidad
- **Enlaces**: Referencias relativas dentro de la documentación  
- **Actualización**: Documentos se mantienen actualizados con cada release
- **Idioma**: Documentación principal en español, código y commits en inglés

## 🔄 Mantenimiento

Esta documentación se actualiza automáticamente como parte del proceso de CI/CD. 
Para sugerir cambios, crear un PR con la etiqueta `documentation`.

---
**Última actualización**: 7 de Octubre de 2025  
**Mantenido por**: Equipo Turnaki-NexioQ