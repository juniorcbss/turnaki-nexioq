# 📁 Guía de Organización del Proyecto

**Turnaki-NexioQ - Sistema SaaS Multi-Tenant de Reservas Odontológicas**

---

## 📋 Índice

1. [Principios de Organización](#-principios-de-organización)
2. [Estructura del Proyecto](#-estructura-del-proyecto)
3. [Convenciones de Nomenclatura](#-convenciones-de-nomenclatura)
4. [Gestión de Archivos](#-gestión-de-archivos)
5. [Backend (Rust)](#-backend-rust)
6. [Frontend (SvelteKit)](#-frontend-sveltekit)
7. [Infraestructura (Terraform)](#-infraestructura-terraform)
8. [Documentación](#-documentación)
9. [Scripts y Automatización](#-scripts-y-automatización)
10. [Testing](#-testing)
11. [Git Workflow](#-git-workflow)
12. [Checklists de Mantenimiento](#-checklists-de-mantenimiento)
13. [Mejores Prácticas](#-mejores-prácticas)

---

## 🎯 Principios de Organización

### Principios Fundamentales

1. **📁 Separación por Dominio**: Cada funcionalidad tiene su propio directorio
2. **🔄 Reutilización**: Código compartido en librerías centralizadas
3. **🌍 Multi-Ambiente**: Configuraciones separadas por entorno (dev/qas/prd)
4. **📚 Documentación**: Cada módulo/componente debe estar documentado
5. **🧪 Testing**: Tests organizados junto al código que prueban
6. **⚡ Automatización**: Scripts para tareas repetitivas
7. **🚀 Escalabilidad**: Estructura que permite agregar features sin restructurar

### Arquitectura de 3 Capas

```
┌─────────────────────────────────────────────────────┐
│                 📱 FRONTEND                          │
│              (SvelteKit + PWA)                      │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────────────┐
│                 🔧 BACKEND                          │
│              (Rust + Lambda)                        │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────────────┐
│               🏗️ INFRAESTRUCTURA                    │
│              (Terraform + AWS)                      │
└─────────────────────────────────────────────────────┘
```

---

## 📂 Estructura del Proyecto

### Vista General

```
turnaki-nexioq/                          # 🏠 Raíz del proyecto
├── 📄 README.md                          # Documentación principal
├── 📄 package.json                       # Workspace npm
├── 📄 CHANGELOG.md                       # Historial de cambios
├── 📄 LICENSE                           # Licencia MIT
│
├── 🦀 backend/                          # Backend Serverless (Rust)
│   ├── 📄 Cargo.toml                    # Workspace Rust
│   ├── 📄 Cargo.lock                    # Lock dependencies
│   ├── 📄 rustfmt.toml                  # Formato código
│   ├── 📄 clippy.toml                   # Linter config
│   ├── 📁 functions/                    # Lambdas por dominio
│   │   ├── 🏥 health/                   # Health check
│   │   ├── 📅 availability/             # Consulta disponibilidad
│   │   ├── 🏢 tenants/                  # CRUD clínicas
│   │   ├── 💉 treatments/               # CRUD tratamientos  
│   │   ├── 👨‍⚕️ professionals/            # CRUD profesionales
│   │   ├── 📝 bookings/                 # CRUD reservas
│   │   ├── 📧 send-notification/        # Envío emails
│   │   └── ⏰ schedule-reminder/        # Recordatorios
│   └── 📁 shared-lib/                   # Librería compartida
│       ├── 📄 Cargo.toml
│       └── 📁 src/
│           ├── 📄 lib.rs                # Re-exports
│           ├── 📄 error.rs              # Manejo errores
│           ├── 📄 response.rs           # HTTP responses
│           ├── 📄 tracing.rs            # Logging
│           └── 📄 dynamodb.rs           # Cliente DynamoDB
│
├── 🎨 frontend/                         # Frontend SPA (SvelteKit)
│   ├── 📄 package.json                  # Dependencies
│   ├── 📄 svelte.config.js              # Config Svelte
│   ├── 📄 vite.config.js                # Config Vite
│   ├── 📄 tsconfig.json                 # TypeScript config
│   ├── 📄 playwright.config.ts          # E2E testing config
│   ├── 📁 src/
│   │   ├── 📄 app.html                  # HTML template
│   │   ├── 📄 config.js                 # Config frontend
│   │   ├── 📁 lib/                      # Utilidades compartidas
│   │   │   ├── 📄 api.svelte.ts         # Cliente API
│   │   │   └── 📄 auth.svelte.ts        # Store autenticación
│   │   └── 📁 routes/                   # Páginas y rutas
│   │       ├── 📄 +page.svelte          # Home
│   │       ├── 📁 booking/              # Wizard reservas
│   │       ├── 📁 my-appointments/      # Portal paciente
│   │       ├── 📁 admin/                # Panel administración
│   │       ├── 📁 calendar/             # Calendario back-office
│   │       └── 📁 auth/                 # OAuth callback
│   ├── 📁 static/                       # Assets estáticos
│   └── 📁 e2e/                          # Tests end-to-end
│       ├── 📄 admin-flow.spec.ts
│       ├── 📄 auth.spec.ts
│       ├── 📄 booking-flow.spec.ts
│       └── ...
│
├── 🏗️ terraform/                        # Infraestructura como Código
│   ├── 📄 README.md                     # Guía Terraform
│   ├── 📁 modules/                      # Módulos reutilizables
│   │   ├── 🔐 iam/                      # Roles y políticas
│   │   ├── 🗄️ dynamodb/                 # Base de datos
│   │   ├── 👤 cognito/                  # Autenticación
│   │   ├── ⚡ lambda/                   # Función genérica
│   │   ├── 🌐 api-gateway/              # HTTP API
│   │   ├── ☁️ s3-cloudfront/            # CDN y hosting
│   │   ├── 🛡️ waf/                      # Firewall web
│   │   ├── 📊 cloudwatch/               # Monitoreo
│   │   └── 📧 ses/                      # Email service
│   ├── 📁 environments/                 # Configuraciones por ambiente
│   │   ├── 🧪 dev/                      # Desarrollo
│   │   ├── 🔍 qas/                      # Quality Assurance
│   │   └── 🚀 prd/                      # Producción
│   └── 📁 scripts/                      # Scripts automatización
│       ├── 📄 validate-modules.sh
│       ├── 📄 apply-dev.sh
│       ├── 📄 apply-qas.sh
│       └── 📄 apply-prd.sh
│
├── 📚 docs/                             # Documentación técnica
│   ├── 📄 README.md                     # Índice documentación
│   ├── 📄 ARCHITECTURE.md               # Arquitectura técnica
│   ├── 📄 API.md                        # Especificación API
│   ├── 📄 DEPLOYMENT.md                 # Guía deployment
│   ├── 📄 DEVELOPMENT.md                # Setup desarrollo
│   ├── 📄 TESTING.md                    # Guía testing
│   ├── 📄 AUTHENTICATION.md             # Flujo auth
│   ├── 📄 RUNBOOK.md                    # Operaciones
│   ├── 📄 ROADMAP.md                    # Roadmap features
│   └── 📁 archive/                      # Documentación histórica
│       ├── 📄 FASE1_COMPLETADA.md
│       ├── 📄 SISTEMA_100_COMPLETADO.md
│       └── ...
│
├── 🔧 scripts/                          # Scripts operativos
│   ├── 📄 create-test-data.sh           # Crear datos prueba
│   ├── 📄 seed-database.sh              # Poblar base datos
│   ├── 📄 seed-dynamo-direct.sh         # Seed DynamoDB directo
│   └── 📄 verify-completion.sh          # Verificar deployment
│
└── 📄 GUIA_ORGANIZACION_PROYECTO.md     # 📋 Este documento
```

---

## 🏷️ Convenciones de Nomenclatura

### 📁 Directorios

| Tipo | Convención | Ejemplo | Descripción |
|------|------------|---------|-------------|
| **Módulos Backend** | `kebab-case` | `send-notification/` | Funciones Lambda |
| **Páginas Frontend** | `kebab-case` | `my-appointments/` | Rutas SvelteKit |
| **Módulos Terraform** | `kebab-case` | `api-gateway/` | Módulos infraestructura |
| **Ambientes** | `lowercase` | `dev/`, `qas/`, `prd/` | Entornos deployment |
| **Documentación** | `UPPERCASE` | `README.md`, `API.md` | Archivos principales |

### 📄 Archivos

| Tipo | Convención | Ejemplo | Descripción |
|------|------------|---------|-------------|
| **Rust** | `snake_case.rs` | `booking_service.rs` | Código Rust |
| **TypeScript** | `camelCase.ts` | `apiClient.ts` | Código TypeScript |
| **Svelte** | `+page.svelte` | `+layout.svelte` | Páginas SvelteKit |
| **Terraform** | `kebab-case.tf` | `main.tf`, `variables.tf` | Infraestructura |
| **Config** | `lowercase.ext` | `package.json`, `cargo.toml` | Configuraciones |
| **Scripts** | `kebab-case.sh` | `deploy-dev.sh` | Scripts bash |

### 🏗️ Recursos AWS (Terraform)

```
{project}-{environment}-{service}-{resource}
```

**Ejemplos**:
- Lambda: `turnaki-nexioq-dev-lambda-bookings`
- DynamoDB: `turnaki-nexioq-dev-main`
- S3: `turnaki-nexioq-dev-frontend`
- Cognito: `turnaki-nexioq-dev-auth-pool`

### 🔧 Variables y Funciones

| Lenguaje | Tipo | Convención | Ejemplo |
|----------|------|------------|---------|
| **Rust** | Variables | `snake_case` | `user_id`, `booking_date` |
| **Rust** | Funciones | `snake_case` | `create_booking()`, `send_email()` |
| **Rust** | Structs | `PascalCase` | `BookingRequest`, `ApiResponse` |
| **TypeScript** | Variables | `camelCase` | `userId`, `bookingDate` |
| **TypeScript** | Funciones | `camelCase` | `createBooking()`, `sendEmail()` |
| **TypeScript** | Interfaces | `PascalCase` | `BookingRequest`, `ApiResponse` |

---

## 🗃️ Gestión de Archivos

### ✅ Archivos que SÍ deben incluirse

```
# Código fuente
✅ src/**/*.rs
✅ src/**/*.ts
✅ src/**/*.svelte
✅ *.tf

# Configuraciones
✅ package.json
✅ Cargo.toml
✅ tsconfig.json
✅ terraform.tfvars

# Documentación
✅ README.md
✅ docs/**/*.md
✅ CHANGELOG.md

# Scripts
✅ scripts/**/*.sh
✅ Makefile

# Testing
✅ tests/**/*.rs
✅ e2e/**/*.spec.ts
```

### ❌ Archivos que NO deben incluirse

```
# Build artifacts
❌ target/
❌ node_modules/
❌ dist/
❌ build/

# IDE específicos
❌ .vscode/
❌ .idea/
❌ *.swp

# OS específicos
❌ .DS_Store
❌ Thumbs.db

# Temporales
❌ *.tmp
❌ *.temp
❌ *.log

# Secrets
❌ .env.local
❌ *.pem
❌ *.key

# Terraform state
❌ *.tfstate
❌ *.tfstate.backup
❌ .terraform/
```

### 📝 .gitignore Principal

```bash
# Build outputs
target/
node_modules/
dist/
build/

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Environment variables
.env.local
.env.*.local

# Terraform
*.tfstate
*.tfstate.backup
.terraform/
*.tfplan

# Rust
Cargo.lock

# Testing
test-results/
playwright-report/

# Temporary
*.tmp
response.json
test-*.html
```

---

## 🦀 Backend (Rust)

### 📁 Estructura de Funciones Lambda

Cada función Lambda sigue la misma estructura:

```
functions/{nombre}/
├── 📄 Cargo.toml              # Dependencies específicas
└── 📁 src/
    └── 📄 main.rs             # Handler principal
```

### 📄 Plantilla Cargo.toml para Lambda

```toml
[package]
name = "{nombre-funcion}"
version = "0.1.0"
edition = "2021"

[[bin]]
name = "bootstrap"
path = "src/main.rs"

[dependencies]
shared-lib = { path = "../../shared-lib" }
lambda_http = "0.13"
lambda_runtime = "0.8"
tokio = { version = "1", features = ["macros"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tracing = "0.1"
```

### 📄 Plantilla main.rs para Lambda

```rust
use lambda_http::{run, service_fn, Body, Error, Request, RequestExt, Response};
use shared_lib::{init_tracing, ApiError, success_response};
use serde_json::json;

async fn function_handler(event: Request) -> Result<Response<Body>, Error> {
    // TODO: Implementar lógica específica
    let response = success_response(json!({
        "message": "Function working correctly"
    }));
    
    Ok(response)
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    init_tracing();
    run(service_fn(function_handler)).await
}
```

### 📚 Shared Library

La librería compartida (`shared-lib/`) debe contener:

```rust
// src/lib.rs
pub mod error;       // Manejo de errores centralizado
pub mod response;    // Builders de respuesta HTTP
pub mod tracing;     // Configuración de logging
pub mod dynamodb;    // Cliente DynamoDB + helpers

// Re-exports para facilitar uso
pub use error::ApiError;
pub use response::{success_response, created_response, error_response};
pub use tracing::init_tracing;
pub use dynamodb::{get_client, table_name};
```

### 🧪 Testing

```
functions/{nombre}/
├── src/
│   └── main.rs
└── tests/                     # Tests de integración
    └── integration_test.rs
```

**Convenciones para tests**:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_function_handler_success() {
        // Arrange
        let event = create_test_request();
        
        // Act
        let response = function_handler(event).await.unwrap();
        
        // Assert
        assert_eq!(response.status(), 200);
    }
}
```

---

## 🎨 Frontend (SvelteKit)

### 📁 Estructura de Rutas

```
src/routes/
├── 📄 +page.svelte                    # Home (/)
├── 📄 +layout.svelte                  # Layout global
├── 📄 +layout.ts                      # Config layout
├── 📁 booking/                        # Wizard reservas (/booking)
│   ├── 📄 +page.svelte
│   └── 📄 +page.ts
├── 📁 my-appointments/                # Portal paciente
│   ├── 📄 +page.svelte
│   └── 📄 +page.server.ts             # Server-side logic
├── 📁 admin/                          # Panel admin
│   ├── 📄 +page.svelte
│   └── 📄 +layout.svelte              # Layout específico admin
└── 📁 auth/                           # OAuth callback
    └── 📁 callback/
        └── 📄 +page.svelte
```

### 📚 Librerías Compartidas

```
src/lib/
├── 📄 api.svelte.ts                   # Cliente API centralizado
├── 📄 auth.svelte.ts                  # Store autenticación
├── 📄 types.ts                        # Types TypeScript
├── 📄 utils.ts                        # Utilidades generales
├── 📁 components/                     # Componentes reutilizables
│   ├── 📄 Button.svelte
│   ├── 📄 Modal.svelte
│   └── 📄 Calendar.svelte
└── 📁 stores/                         # Svelte stores
    ├── 📄 user.svelte.ts
    ├── 📄 bookings.svelte.ts
    └── 📄 notifications.svelte.ts
```

### 📄 Plantilla de Componente

```svelte
<!-- src/lib/components/Example.svelte -->
<script lang="ts">
  // Props
  interface Props {
    title: string;
    variant?: 'primary' | 'secondary';
  }
  
  const { title, variant = 'primary' }: Props = $props();
  
  // State reactivo
  let isVisible = $state(false);
  
  // Computed
  const cssClass = $derived(`btn btn-${variant}`);
</script>

<div class={cssClass}>
  <h2>{title}</h2>
  <!-- Contenido -->
</div>

<style>
  .btn {
    /* Estilos base */
  }
</style>
```

### 🧪 Testing Frontend

```
src/lib/
├── 📄 api.svelte.test.ts              # Tests unitarios
└── 📄 auth.svelte.test.ts

e2e/
├── 📄 auth.spec.ts                    # Tests E2E por feature
├── 📄 booking-flow.spec.ts
├── 📄 admin-flow.spec.ts
└── 📄 my-appointments.spec.ts
```

### ⚙️ Configuración

```typescript
// src/config.js - Variables de configuración
export const config = {
  api: {
    baseUrl: import.meta.env.VITE_API_BASE,
    timeout: 10000
  },
  cognito: {
    domain: import.meta.env.VITE_COGNITO_DOMAIN,
    clientId: import.meta.env.VITE_COGNITO_CLIENT_ID,
    redirectUri: import.meta.env.VITE_COGNITO_REDIRECT_URI
  },
  app: {
    name: 'Turnaki-NexioQ',
    version: '2.0.0'
  }
};
```

---

## 🏗️ Infraestructura (Terraform)

### 📁 Estructura de Módulos

Cada módulo Terraform sigue esta estructura estándar:

```
modules/{nombre}/
├── 📄 README.md                       # Documentación del módulo
├── 📄 main.tf                         # Recursos principales
├── 📄 variables.tf                    # Variables de entrada
├── 📄 outputs.tf                      # Outputs del módulo
└── 📄 versions.tf                     # Versiones providers (opcional)
```

### 📄 Plantilla variables.tf

```hcl
# modules/ejemplo/variables.tf
variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Solo se permiten minúsculas, números y guiones."
  }
}

variable "environment" {
  description = "Ambiente de deployment"
  type        = string
  
  validation {
    condition     = contains(["dev", "qas", "prd"], var.environment)
    error_message = "Ambiente debe ser: dev, qas, o prd."
  }
}

variable "tags" {
  description = "Tags por defecto para todos los recursos"
  type        = map(string)
  default     = {}
}
```

### 📄 Plantilla outputs.tf

```hcl
# modules/ejemplo/outputs.tf
output "resource_id" {
  description = "ID del recurso creado"
  value       = aws_ejemplo_resource.main.id
}

output "resource_arn" {
  description = "ARN del recurso creado"
  value       = aws_ejemplo_resource.main.arn
  sensitive   = false
}
```

### 🌍 Estructura de Ambientes

```
environments/{env}/
├── 📄 main.tf                         # Orquestación de módulos
├── 📄 variables.tf                    # Variables del ambiente
├── 📄 terraform.tfvars                # Valores específicos
├── 📄 backend.tf                      # Config backend S3
├── 📄 outputs.tf                      # Outputs del ambiente
└── 📄 versions.tf                     # Providers y versiones
```

### 📄 Plantilla main.tf (ambiente)

```hcl
# environments/dev/main.tf
locals {
  project_name = "turnaki-nexioq"
  environment  = "dev"
  
  common_tags = {
    Project     = "Turnaki-NexioQ"
    Environment = local.environment
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
  }
}

# Módulo DynamoDB
module "dynamodb" {
  source = "../../modules/dynamodb"
  
  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags
}

# Módulo Lambda para cada función
module "lambda_bookings" {
  source = "../../modules/lambda"
  
  project_name    = local.project_name
  environment     = local.environment
  function_name   = "bookings"
  handler_zip     = "../../backend/target/lambda/bookings/bootstrap.zip"
  environment_vars = {
    TABLE_NAME = module.dynamodb.table_name
  }
  
  tags = local.common_tags
}
```

### 🔧 Scripts de Automatización

```bash
# terraform/scripts/apply-dev.sh
#!/bin/bash
set -euo pipefail

echo "🚀 Deployando ambiente DEV..."

cd "$(dirname "$0")/../environments/dev"

# Validar configuración
terraform validate

# Plan con output detallado  
terraform plan -out=tfplan

# Aplicar cambios
terraform apply tfplan

# Limpiar plan
rm -f tfplan

echo "✅ Deploy DEV completado!"
```

---

## 📚 Documentación

### 📁 Estructura de Documentos

```
docs/
├── 📄 README.md                       # Índice de documentación
├── 📄 ARCHITECTURE.md                 # Diseño técnico
├── 📄 API.md                          # Especificación endpoints
├── 📄 DEPLOYMENT.md                   # Guía de deployment
├── 📄 DEVELOPMENT.md                  # Setup desarrollo local
├── 📄 TESTING.md                      # Estrategia testing
├── 📄 AUTHENTICATION.md               # Flujo OAuth
├── 📄 RUNBOOK.md                      # Operaciones y troubleshooting
├── 📄 ROADMAP.md                      # Features futuras
└── 📁 archive/                        # Documentación histórica
    ├── 📄 FASE1_COMPLETADA.md
    ├── 📄 SISTEMA_100_COMPLETADO.md
    └── 📄 RESUMEN_FINAL.md
```

### 📝 Plantilla de Documento

```markdown
# 📊 Título del Documento

**Descripción breve del documento**

---

## 📋 Tabla de Contenidos

1. [Sección 1](#sección-1)
2. [Sección 2](#sección-2)
3. [Referencias](#referencias)

---

## 🎯 Sección Principal

### Subsección

Contenido con ejemplos de código:

```bash
# Comando de ejemplo
npm run build
```

### Diagramas

```
┌─────────────┐
│   Ejemplo   │
│  Diagrama   │
└─────────────┘
```

---

## 📚 Referencias

- [Enlace externo](https://example.com)
- [Documento interno](./OTRO_DOC.md)

---

**Última actualización**: {fecha}  
**Versión**: {version}  
**Mantenido por**: {equipo}
```

### 🔄 Mantenimiento de Documentación

**Reglas para mantener documentación actualizada**:

1. **📝 Al agregar features**: Actualizar `API.md` y `ARCHITECTURE.md`
2. **🔧 Al cambiar deployment**: Actualizar `DEPLOYMENT.md`
3. **📦 Al cambiar dependencies**: Actualizar `DEVELOPMENT.md`
4. **🧪 Al agregar tests**: Actualizar `TESTING.md`
5. **🐛 Al resolver issues**: Actualizar `RUNBOOK.md`

**Documentación histórica**:
- Mover documentos obsoletos a `docs/archive/`
- Mantener referencia en documento principal
- Agregar fecha de archivado

---

## 🔧 Scripts y Automatización

### 📁 Ubicación de Scripts

```
scripts/                              # Scripts del proyecto
├── 📄 create-test-data.sh           # Poblar datos de prueba
├── 📄 seed-database.sh              # Seed base datos
├── 📄 verify-completion.sh          # Verificar deployment
└── 📄 backup-database.sh            # Backup DynamoDB

terraform/scripts/                    # Scripts Terraform
├── 📄 validate-modules.sh           # Validar módulos
├── 📄 format-all.sh                 # Formatear código
├── 📄 apply-dev.sh                  # Deploy dev
├── 📄 apply-qas.sh                  # Deploy qas
├── 📄 apply-prd.sh                  # Deploy prd
└── 📄 destroy-dev.sh                # Destruir dev

frontend/scripts/                     # Scripts frontend (si aplica)
└── 📄 build-pwa.sh                  # Build PWA
```

### 📄 Plantilla de Script

```bash
#!/bin/bash
# 📄 Plantilla de script
# Descripción: {Propósito del script}
# Autor: {nombre}
# Fecha: {fecha}

# Configuración estricta
set -euo pipefail

# Variables globales
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Funciones
log_info() {
    echo "ℹ️  $*" >&2
}

log_error() {
    echo "❌ ERROR: $*" >&2
}

log_success() {
    echo "✅ $*" >&2
}

# Validaciones iniciales
validate_requirements() {
    command -v aws >/dev/null 2>&1 || { 
        log_error "AWS CLI no encontrado"
        exit 1
    }
}

# Función principal
main() {
    log_info "Iniciando ${0##*/}..."
    
    validate_requirements
    
    # Lógica principal aquí
    
    log_success "Script completado exitosamente!"
}

# Ejecutar si es invocado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### 🔒 Permisos de Scripts

```bash
# Hacer scripts ejecutables
chmod +x scripts/*.sh
chmod +x terraform/scripts/*.sh

# Verificar permisos
ls -la scripts/
```

---

## 🧪 Testing

### 📁 Organización de Tests

```
# Backend Tests
backend/
├── functions/
│   └── bookings/
│       ├── src/main.rs
│       └── tests/                   # Tests específicos función
│           └── integration_test.rs
└── shared-lib/
    └── src/
        ├── error.rs
        └── error.test.rs           # Tests junto al código

# Frontend Tests  
frontend/
├── src/
│   └── lib/
│       ├── api.svelte.ts
│       └── api.svelte.test.ts      # Tests unitarios
└── e2e/                            # Tests end-to-end
    ├── auth.spec.ts
    ├── booking-flow.spec.ts
    └── admin-flow.spec.ts

# Infrastructure Tests
terraform/
├── modules/
│   └── lambda/
│       └── main.tf
└── tests/                          # Tests infraestructura
    ├── validate_modules.sh
    └── terratest/                  # Go terratest (opcional)
```

### 📝 Convenciones de Naming

| Tipo Test | Convención | Ejemplo |
|-----------|------------|---------|
| **Unit (Rust)** | `test_function_name` | `test_create_booking_success` |
| **Unit (TS)** | `should_do_something` | `should_create_booking_successfully` |
| **E2E** | `feature.spec.ts` | `booking-flow.spec.ts` |
| **Integration** | `integration_test.rs` | `booking_integration_test.rs` |

### 🎯 Test Categories

```rust
// Rust - Categorizar tests con cfg
#[cfg(test)]
mod unit_tests {
    // Tests unitarios rápidos
}

#[cfg(test)]
#[cfg(feature = "integration")]
mod integration_tests {
    // Tests que requieren recursos externos
}
```

```typescript
// TypeScript - Agrupar por describe
describe('API Client', () => {
  describe('Authentication', () => {
    it('should handle login success', () => {
      // Test específico
    });
  });
  
  describe('Bookings', () => {
    it('should create booking', () => {
      // Test específico
    });
  });
});
```

---

## 🔀 Git Workflow

### 🌳 Estructura de Ramas

```
main                    # Rama principal (protegida)
├── develop            # Rama de desarrollo (opcional)
├── feature/AUTH-123   # Features nuevas  
├── fix/BUG-456       # Corrección de bugs
├── hotfix/URGENT-789 # Fixes urgentes producción
└── release/v2.1.0    # Preparación releases
```

### 📋 Naming Convention Ramas

| Tipo | Formato | Ejemplo |
|------|---------|---------|
| **Feature** | `feature/TICKET-descripcion` | `feature/AUTH-123-oauth-integration` |
| **Bugfix** | `fix/TICKET-descripcion` | `fix/BUG-456-calendar-timezone` |
| **Hotfix** | `hotfix/TICKET-descripcion` | `hotfix/URGENT-789-payment-failure` |
| **Release** | `release/vX.Y.Z` | `release/v2.1.0` |

### 💬 Commit Messages

Seguir [Conventional Commits](https://www.conventionalcommits.org/):

```
tipo(scope): descripción breve

Descripción más detallada si es necesario.

- Cambio específico 1
- Cambio específico 2

Closes #123
```

**Tipos permitidos**:
- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `docs`: Cambios en documentación
- `style`: Formateo, espacios en blanco
- `refactor`: Refactoring de código
- `test`: Agregar o modificar tests
- `chore`: Tareas de mantenimiento

**Ejemplos**:

```bash
feat(auth): add OAuth 2.0 integration with Cognito

- Implement login/logout flow
- Add JWT token validation
- Update auth store with user state

Closes #123

fix(booking): resolve timezone issue in calendar

The calendar was showing incorrect times due to 
timezone conversion bug in the date picker.

- Fix timezone conversion logic
- Add tests for edge cases
- Update documentation

Closes #456

docs(api): update endpoints documentation

- Add new booking endpoints
- Fix response examples
- Update authentication section
```

### 🔒 Branch Protection Rules

**Para rama `main`**:

```yaml
# Configuración en GitHub
protection_rules:
  required_status_checks:
    - "build/backend"
    - "build/frontend" 
    - "terraform/validate"
  
  required_reviews: 2
  dismiss_stale_reviews: true
  require_code_owner_reviews: true
  
  restrictions:
    - "developers"
    - "devops"
  
  enforce_admins: false
```

---

## ✅ Checklists de Mantenimiento

### 📋 Checklist: Nueva Feature

**Antes de empezar**:
- [ ] Crear ticket en issue tracker
- [ ] Crear rama desde `main`: `feature/TICKET-descripcion`
- [ ] Verificar que la estructura del proyecto esté actualizada

**Durante desarrollo**:
- [ ] Seguir convenciones de nomenclatura
- [ ] Agregar tests unitarios (mínimo 80% coverage)
- [ ] Actualizar documentación relevante
- [ ] Verificar que no se rompan tests existentes
- [ ] Agregar logs apropiados con `tracing`
- [ ] Validar que funcione en ambiente local

**Antes del PR**:
- [ ] Ejecutar linter: `npm run lint`
- [ ] Ejecutar tests: `npm test`
- [ ] Ejecutar tests E2E: `npm run test:e2e`
- [ ] Verificar build: `npm run build`
- [ ] Actualizar `CHANGELOG.md` si aplica
- [ ] Hacer squash de commits si es necesario

**PR Review**:
- [ ] Descripción clara del cambio
- [ ] Screenshots si aplica (UI changes)
- [ ] Tests passing en CI
- [ ] Aprobación de al menos 2 reviewers
- [ ] Merge y delete rama

### 📋 Checklist: Release

**Preparación**:
- [ ] Crear rama `release/vX.Y.Z`
- [ ] Actualizar versiones en:
  - [ ] `package.json` (raíz)
  - [ ] `frontend/package.json`
  - [ ] `backend/Cargo.toml`
- [ ] Actualizar `CHANGELOG.md` con todos los cambios
- [ ] Ejecutar suite completa de tests
- [ ] Verificar deployment en ambiente QAS

**Release**:
- [ ] Merge a `main`
- [ ] Crear tag: `git tag v2.1.0`
- [ ] Push tag: `git push origin v2.1.0`
- [ ] Deploy a producción
- [ ] Verificar funcionamiento en PRD
- [ ] Comunicar release al equipo

**Post-release**:
- [ ] Monitorear logs por 24 horas
- [ ] Verificar métricas en CloudWatch
- [ ] Actualizar documentación de usuario si aplica
- [ ] Archivar documentos obsoletos

### 📋 Checklist: Mantenimiento Mensual

**Dependencias**:
- [ ] Actualizar dependencias Rust: `cargo update`
- [ ] Actualizar dependencias npm: `npm update`
- [ ] Verificar vulnerabilidades: `npm audit`
- [ ] Actualizar Terraform providers
- [ ] Revisar advisories de seguridad

**Infraestructura**:
- [ ] Revisar costos AWS por servicio
- [ ] Verificar alarmas CloudWatch
- [ ] Limpiar logs antiguos
- [ ] Verificar backups DynamoDB
- [ ] Revisar métricas de performance

**Código**:
- [ ] Revisar TODOs y FIXMEs en código
- [ ] Ejecutar análisis estático: `cargo clippy`
- [ ] Verificar coverage de tests
- [ ] Limpiar código muerto
- [ ] Actualizar documentación técnica

**Documentación**:
- [ ] Revisar y actualizar READMEs
- [ ] Verificar enlaces rotos en docs
- [ ] Actualizar diagramas de arquitectura
- [ ] Archivar documentos obsoletos
- [ ] Revisar roadmap y prioridades

### 📋 Checklist: Troubleshooting

**Problema en Producción**:
- [ ] Identificar alcance del problema
- [ ] Revisar logs en CloudWatch
- [ ] Verificar métricas y alarmas
- [ ] Comunicar estado al equipo
- [ ] Implementar fix temporal si es necesario
- [ ] Crear hotfix branch si aplica
- [ ] Hacer root cause analysis
- [ ] Actualizar runbook con solución
- [ ] Implementar mejoras para prevenir recurrencia

**Performance Issues**:
- [ ] Revisar métricas de latencia
- [ ] Verificar utilización de recursos
- [ ] Analizar queries DynamoDB
- [ ] Revisar logs de X-Ray
- [ ] Verificar configuración de Lambda
- [ ] Optimizar código si es necesario
- [ ] Ajustar configuración de infraestructura

---

## 🏆 Mejores Prácticas

### 💎 Principios Generales

1. **🔍 DRY (Don't Repeat Yourself)**
   - Extraer lógica común a librerías compartidas
   - Reutilizar módulos Terraform entre ambientes
   - Compartir utilidades entre componentes frontend

2. **📏 KISS (Keep It Simple, Stupid)**
   - Prefiere soluciones simples sobre complejas
   - Evita over-engineering
   - Documenta decisiones arquitectónicas

3. **🔒 Fail Fast**
   - Validar inputs tempranamente
   - Usar types estrictos (Rust, TypeScript)
   - Implementar circuit breakers donde aplique

4. **📊 Observabilidad First**
   - Agregar logs estructurados
   - Implementar métricas custom
   - Usar distributed tracing

### 🦀 Backend (Rust) Best Practices

```rust
// ✅ Buenas prácticas

// 1. Error handling explícito
#[derive(Debug, thiserror::Error)]
pub enum BookingError {
    #[error("Booking not found: {id}")]
    NotFound { id: String },
    
    #[error("Database error: {source}")]
    Database {
        #[from]
        source: aws_sdk_dynamodb::Error,
    },
}

// 2. Usar types específicos en lugar de primitivos
#[derive(Debug, Clone)]
pub struct BookingId(String);

impl BookingId {
    pub fn new(id: String) -> Result<Self, ValidationError> {
        if id.is_empty() {
            return Err(ValidationError::EmptyId);
        }
        Ok(BookingId(id))
    }
}

// 3. Separar lógica de negocio del handler
pub async fn create_booking(request: CreateBookingRequest) -> Result<Booking, BookingError> {
    // Lógica pura sin dependencias externas
    let booking = Booking::new(request)?;
    
    // Persistencia
    let client = get_client().await;
    save_booking(&client, &booking).await?;
    
    Ok(booking)
}

// 4. Tests exhaustivos
#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn create_booking_success() {
        // Arrange
        let request = CreateBookingRequest {
            patient_id: "patient123".to_string(),
            // ...
        };
        
        // Act
        let result = create_booking(request).await;
        
        // Assert
        assert!(result.is_ok());
        let booking = result.unwrap();
        assert_eq!(booking.patient_id, "patient123");
    }
    
    #[tokio::test]
    async fn create_booking_invalid_input() {
        let request = CreateBookingRequest {
            patient_id: "".to_string(), // Invalid
        };
        
        let result = create_booking(request).await;
        assert!(matches!(result, Err(BookingError::InvalidInput(_))));
    }
}
```

### 🎨 Frontend (SvelteKit) Best Practices

```typescript
// ✅ Buenas prácticas

// 1. Types estrictos
interface BookingRequest {
  readonly patientId: string;
  readonly treatmentId: string;
  readonly dateTime: Date;
  readonly notes?: string;
}

interface ApiResponse<T> {
  readonly success: boolean;
  readonly data?: T;
  readonly error?: string;
}

// 2. Error handling consistente
class ApiClient {
  async createBooking(request: BookingRequest): Promise<ApiResponse<Booking>> {
    try {
      const response = await fetch('/api/bookings', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${getToken()}`
        },
        body: JSON.stringify(request)
      });
      
      if (!response.ok) {
        return {
          success: false,
          error: `HTTP ${response.status}: ${response.statusText}`
        };
      }
      
      const data = await response.json();
      return { success: true, data };
      
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }
}

// 3. Stores reactivos bien estructurados
// src/lib/stores/booking.svelte.ts
class BookingStore {
  private bookings = $state<Booking[]>([]);
  private loading = $state(false);
  private error = $state<string | null>(null);
  
  // Getters reactivos
  get allBookings() { return this.bookings; }
  get isLoading() { return this.loading; }
  get hasError() { return this.error !== null; }
  
  // Actions
  async loadBookings(): Promise<void> {
    this.loading = true;
    this.error = null;
    
    try {
      const response = await apiClient.getBookings();
      if (response.success) {
        this.bookings = response.data ?? [];
      } else {
        this.error = response.error ?? 'Failed to load bookings';
      }
    } catch (err) {
      this.error = err instanceof Error ? err.message : 'Unknown error';
    } finally {
      this.loading = false;
    }
  }
}

export const bookingStore = new BookingStore();

// 4. Components con props tipados
<!-- src/lib/components/BookingCard.svelte -->
<script lang="ts">
  interface Props {
    booking: Booking;
    editable?: boolean;
    onEdit?: (booking: Booking) => void;
    onDelete?: (id: string) => void;
  }
  
  const { 
    booking, 
    editable = false, 
    onEdit, 
    onDelete 
  }: Props = $props();
  
  // Computed values
  const formattedDate = $derived(
    new Intl.DateTimeFormat('es-EC', {
      dateStyle: 'medium',
      timeStyle: 'short'
    }).format(new Date(booking.dateTime))
  );
  
  function handleEdit() {
    onEdit?.(booking);
  }
  
  function handleDelete() {
    if (confirm('¿Estás seguro de eliminar esta cita?')) {
      onDelete?.(booking.id);
    }
  }
</script>

<div class="booking-card">
  <h3>{booking.treatmentName}</h3>
  <p>{formattedDate}</p>
  <p>{booking.professionalName}</p>
  
  {#if editable}
    <div class="actions">
      <button onclick={handleEdit}>Editar</button>
      <button onclick={handleDelete}>Eliminar</button>
    </div>
  {/if}
</div>
```

### 🏗️ Infrastructure (Terraform) Best Practices

```hcl
# ✅ Buenas prácticas

# 1. Variables con validación
variable "environment" {
  description = "Ambiente de deployment (dev, qas, prd)"
  type        = string
  
  validation {
    condition     = contains(["dev", "qas", "prd"], var.environment)
    error_message = "Environment debe ser uno de: dev, qas, prd."
  }
}

variable "lambda_memory_mb" {
  description = "Memoria para funciones Lambda en MB"
  type        = number
  default     = 512
  
  validation {
    condition     = var.lambda_memory_mb >= 128 && var.lambda_memory_mb <= 10240
    error_message = "Lambda memory debe estar entre 128 y 10240 MB."
  }
}

# 2. Locals para cálculos complejos
locals {
  # Naming convention consistente
  resource_prefix = "${var.project_name}-${var.environment}"
  
  # Tags estándar
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  })
  
  # Configuración por ambiente
  config = {
    dev = {
      lambda_memory = 512
      dynamodb_billing_mode = "PAY_PER_REQUEST"
      log_retention_days = 7
    }
    qas = {
      lambda_memory = 1024
      dynamodb_billing_mode = "PAY_PER_REQUEST"
      log_retention_days = 14
    }
    prd = {
      lambda_memory = 1024
      dynamodb_billing_mode = "PROVISIONED"
      log_retention_days = 90
    }
  }
  
  current_config = local.config[var.environment]
}

# 3. Outputs útiles
output "api_endpoint" {
  description = "URL del API Gateway"
  value       = module.api_gateway.api_endpoint
  
  # No marcar como sensitive endpoints públicos
  sensitive = false
}

output "lambda_function_names" {
  description = "Lista de nombres de funciones Lambda"
  value = [
    module.lambda_health.function_name,
    module.lambda_bookings.function_name,
    # ...
  ]
}

# 4. Data sources para referencias externas
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# 5. Recursos con configuración robusta
resource "aws_lambda_function" "main" {
  function_name = "${local.resource_prefix}-${var.function_name}"
  filename      = var.zip_path
  handler       = "bootstrap"
  runtime       = "provided.al2023"
  architecture  = ["arm64"]
  
  memory_size = local.current_config.lambda_memory
  timeout     = var.timeout
  
  # Variables de entorno
  environment {
    variables = merge({
      RUST_LOG    = var.environment == "dev" ? "debug" : "info"
      TABLE_NAME  = var.table_name
      REGION      = data.aws_region.current.name
    }, var.environment_variables)
  }
  
  # Observabilidad
  tracing_config {
    mode = "Active"
  }
  
  # Logging
  depends_on = [aws_cloudwatch_log_group.lambda]
  
  tags = local.common_tags
  
  lifecycle {
    # Prevenir recreación accidental
    create_before_destroy = true
    
    # Ignorar cambios en el zip durante development
    ignore_changes = var.environment == "dev" ? [filename] : []
  }
}

# 6. Outputs con data transformation
output "lambda_info" {
  description = "Información completa de la función Lambda"
  value = {
    arn           = aws_lambda_function.main.arn
    function_name = aws_lambda_function.main.function_name
    memory_size   = aws_lambda_function.main.memory_size
    runtime       = aws_lambda_function.main.runtime
    last_modified = aws_lambda_function.main.last_modified
  }
}
```

### 📊 Monitoring Best Practices

```hcl
# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.resource_prefix}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", module.lambda_bookings.function_name],
            ["AWS/Lambda", "Errors", "FunctionName", module.lambda_bookings.function_name],
            ["AWS/Lambda", "Duration", "FunctionName", module.lambda_bookings.function_name]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Lambda Metrics - Bookings"
        }
      }
    ]
  })
}

# Alarmas críticas
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.resource_prefix}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Lambda function errors"
  
  dimensions = {
    FunctionName = module.lambda_bookings.function_name
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  
  tags = local.common_tags
}
```

---

## 🎯 Conclusión

Esta guía establece las bases para mantener el proyecto **Turnaki-NexioQ** organizado y escalable. Siguiendo estas convenciones y mejores prácticas, el equipo puede:

- ✅ Mantener consistencia en la estructura del código
- ✅ Facilitar onboarding de nuevos desarrolladores  
- ✅ Reducir tiempo de debugging y troubleshooting
- ✅ Escalr la aplicación sin refactoring major
- ✅ Mantener alta calidad y mantenibilidad del código

### 📚 Recursos Adicionales

- **[Documentación Rust](https://doc.rust-lang.org/)** - Lenguaje backend
- **[SvelteKit Docs](https://kit.svelte.dev/)** - Framework frontend  
- **[Terraform Best Practices](https://www.terraform-best-practices.com/)** - Infraestructura
- **[AWS Well-Architected](https://aws.amazon.com/architecture/well-architected/)** - Arquitectura cloud
- **[Conventional Commits](https://www.conventionalcommits.org/)** - Formato commits

### 🔄 Actualizaciones

Este documento debe revisarse y actualizarse:
- 📅 **Mensualmente**: Revisar y ajustar convenciones
- 🚀 **Cada release**: Incorporar lecciones aprendidas
- 🏗️ **Cambios arquitectónicos**: Actualizar estructura y ejemplos

---

**📝 Documento creado por**: Análisis completo del proyecto Turnaki-NexioQ  
**📅 Última actualización**: 7 de Octubre de 2025  
**📊 Versión**: 1.0.0  
**👥 Mantenido por**: Equipo de Desarrollo Turnaki-NexioQ
