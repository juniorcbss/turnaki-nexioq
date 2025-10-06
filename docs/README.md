# 📚 Documentación Turnaki-NexioQ

**Sistema SaaS Multi-Tenant de Reservas Odontológicas**

---

## 📑 Índice de Documentación

### Guías Principales

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Arquitectura técnica del sistema
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Guía de deployment con Terraform
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Setup y desarrollo local
- **[AUTHENTICATION.md](AUTHENTICATION.md)** - Flujo de autenticación con Cognito
- **[API.md](API.md)** - Especificación de endpoints
- **[TESTING.md](TESTING.md)** - Testing E2E y unitario
- **[RUNBOOK.md](RUNBOOK.md)** - Operaciones y troubleshooting
- **[ROADMAP.md](ROADMAP.md)** - Mejoras y features pendientes
- **[CHANGELOG.md](CHANGELOG.md)** - Historial de cambios

### Documentos Archivados

Los documentos históricos del desarrollo se encuentran en [`archive/`](archive/)

---

## 🚀 Quick Start

### Para Desarrolladores

1. **Setup inicial**: Ver [DEVELOPMENT.md](DEVELOPMENT.md#setup-inicial)
2. **Autenticación**: Ver [AUTHENTICATION.md](AUTHENTICATION.md#cómo-hacer-login)
3. **Running tests**: Ver [TESTING.md](TESTING.md#comandos-de-ejecución)

### Para DevOps

1. **Deploy Terraform**: Ver [DEPLOYMENT.md](DEPLOYMENT.md#deployment)
2. **Troubleshooting**: Ver [RUNBOOK.md](RUNBOOK.md#troubleshooting-común)
3. **Rollback**: Ver [RUNBOOK.md](RUNBOOK.md#rollback-y-recuperación)

---

## 🏗️ Stack Tecnológico

| Capa | Tecnología |
|------|------------|
| **Frontend** | SvelteKit 5 + TypeScript |
| **Backend** | Rust 1.89 + AWS Lambda |
| **Database** | DynamoDB (single-table) |
| **Auth** | Cognito User Pool + JWT |
| **IaC** | Terraform 1.9 |
| **Monitoring** | CloudWatch + X-Ray |

---

## 📊 Estado Actual

**✅ Sistema 100% Funcional - Listo para Producción**

- **Backend**: 8 Lambdas serverless operativas
- **Frontend**: PWA con Svelte 5
- **Infraestructura**: Multi-ambiente (dev/qas/prd) con Terraform
- **Testing**: 85% coverage en funciones críticas

Ver [CHANGELOG.md](CHANGELOG.md) para historial completo.

---

## 🤝 Contribuir

Para contribuir al proyecto:

1. Fork el repositorio
2. Crea una rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. Sigue las guías en [DEVELOPMENT.md](DEVELOPMENT.md)
4. Ejecuta tests (`npm test`)
5. Crea un Pull Request

---

## 📞 Soporte

- 📧 Email: devops@turnaki.com
- 📚 Docs: Este directorio
- 🐛 Issues: GitHub Issues

---

**Última actualización**: Octubre 2025  
**Versión**: 2.0.0 (Migración a Terraform)
