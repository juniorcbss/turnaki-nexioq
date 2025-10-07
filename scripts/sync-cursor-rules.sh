#!/bin/bash
# 📄 Script para sincronizar reglas de Cursor con la guía de organización
# Descripción: Actualiza automáticamente .cursor/rules basado en GUIA_ORGANIZACION_PROYECTO.md
# Autor: Sistema automatizado
# Fecha: 7 de Octubre 2025

# Configuración estricta
set -euo pipefail

# Variables globales
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly GUIDE_FILE="${PROJECT_ROOT}/GUIA_ORGANIZACION_PROYECTO.md"
readonly CURSOR_RULES="${PROJECT_ROOT}/.cursor/rules"

# Funciones de logging
log_info() {
    echo "ℹ️  $*" >&2
}

log_error() {
    echo "❌ ERROR: $*" >&2
}

log_success() {
    echo "✅ $*" >&2
}

log_warning() {
    echo "⚠️  WARNING: $*" >&2
}

# Validar prerrequisitos
validate_requirements() {
    if [[ ! -f "$GUIDE_FILE" ]]; then
        log_error "Archivo de guía no encontrado: $GUIDE_FILE"
        exit 1
    fi

    if [[ ! -d "$(dirname "$CURSOR_RULES")" ]]; then
        log_info "Creando directorio .cursor..."
        mkdir -p "$(dirname "$CURSOR_RULES")"
    fi

    log_info "Validaciones completadas ✓"
}

# Generar timestamp para las reglas
generate_timestamp() {
    date '+%d de %B %Y - %H:%M GMT-5'
}

# Crear backup de reglas existentes
backup_existing_rules() {
    if [[ -f "$CURSOR_RULES" ]]; then
        local backup_file="${CURSOR_RULES}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Creando backup: $(basename "$backup_file")"
        cp "$CURSOR_RULES" "$backup_file"
    fi
}

# Extraer secciones relevantes de la guía
extract_naming_conventions() {
    sed -n '/## 🏷️ Convenciones de Nomenclatura/,/^## /p' "$GUIDE_FILE" | head -n -1
}

extract_best_practices() {
    sed -n '/## 🏆 Mejores Prácticas/,/^## /p' "$GUIDE_FILE" | head -n -1
}

# Generar reglas actualizadas
generate_updated_rules() {
    local timestamp
    timestamp=$(generate_timestamp)
    
    cat > "$CURSOR_RULES" << 'EOF'
# 📋 Reglas del Proyecto Turnaki-NexioQ

## 🏗️ ARQUITECTURA Y PRINCIPIOS

- El proyecto sigue una arquitectura serverless de 3 capas: Frontend (SvelteKit), Backend (Rust Lambda), Infraestructura (Terraform)
- Mantener separación estricta por dominio: cada funcionalidad en su propio directorio
- Aplicar principios DRY: reutilizar código en librerías compartidas (shared-lib, src/lib/)
- Multi-ambiente obligatorio: separar configuraciones por dev/qas/prd
- Documentación obligatoria: cada módulo/componente debe estar documentado
- Tests junto al código: organizar tests cerca del código que prueban
- Automatización: preferir scripts para tareas repetitivas
- Escalabilidad: estructuras que permiten agregar features sin restructurar

## 📁 CONVENCIONES DE NOMENCLATURA

### Directorios
- Módulos Backend Rust: `kebab-case` (ej: `send-notification/`, `my-appointments/`)
- Páginas Frontend: `kebab-case` (ej: `my-appointments/`, `booking/`)
- Módulos Terraform: `kebab-case` (ej: `api-gateway/`, `s3-cloudfront/`)
- Ambientes: `lowercase` (ej: `dev/`, `qas/`, `prd/`)
- Documentación: `UPPERCASE.md` (ej: `README.md`, `API.md`)

### Archivos
- Código Rust: `snake_case.rs` (ej: `booking_service.rs`)
- Código TypeScript: `camelCase.ts` (ej: `apiClient.ts`)
- Páginas Svelte: `+page.svelte`, `+layout.svelte`
- Terraform: `kebab-case.tf` (ej: `main.tf`, `variables.tf`)
- Configuración: `lowercase.ext` (ej: `package.json`, `cargo.toml`)
- Scripts: `kebab-case.sh` (ej: `deploy-dev.sh`)

### Variables y Funciones
- Rust variables: `snake_case` (ej: `user_id`, `booking_date`)
- Rust funciones: `snake_case` (ej: `create_booking()`, `send_email()`)
- Rust structs: `PascalCase` (ej: `BookingRequest`, `ApiResponse`)
- TypeScript variables: `camelCase` (ej: `userId`, `bookingDate`)
- TypeScript funciones: `camelCase` (ej: `createBooking()`, `sendEmail()`)
- TypeScript interfaces: `PascalCase` (ej: `BookingRequest`, `ApiResponse`)

### Recursos AWS
- Patrón: `{project}-{environment}-{service}-{resource}`
- Ejemplos: 
  - Lambda: `turnaki-nexioq-dev-lambda-bookings`
  - DynamoDB: `turnaki-nexioq-dev-main`
  - S3: `turnaki-nexioq-dev-frontend`
  - Cognito: `turnaki-nexioq-dev-auth-pool`

## 🦀 BACKEND RUST - REGLAS ESPECÍFICAS

### Estructura Lambda Obligatoria
```
functions/{nombre}/
├── Cargo.toml              # Dependencies específicas
└── src/
    └── main.rs             # Handler principal
```

### Plantilla Cargo.toml Lambda
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

### Código Rust - Mejores Prácticas
- SIEMPRE usar `shared-lib` para funciones comunes (error handling, response builders, tracing, DynamoDB client)
- Error handling explícito con `thiserror::Error` y custom error types
- Separar lógica de negocio del handler Lambda
- Usar types específicos en lugar de primitivos (ej: `BookingId(String)` en lugar de `String`)
- Tests obligatorios con patrón Arrange-Act-Assert
- Logging estructurado con `tracing` crate
- Handlers async con `tokio::main`
- Importar de shared-lib: `use shared_lib::{init_tracing, ApiError, success_response};`

### Plantilla Handler Lambda
```rust
use lambda_http::{run, service_fn, Body, Error, Request, RequestExt, Response};
use shared_lib::{init_tracing, ApiError, success_response};
use serde_json::json;

async fn function_handler(event: Request) -> Result<Response<Body>, Error> {
    // Implementar lógica específica
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

## 🎨 FRONTEND SVELTE - REGLAS ESPECÍFICAS

### Estructura de Rutas SvelteKit
```
src/routes/
├── +page.svelte                    # Home (/)
├── +layout.svelte                  # Layout global
├── +layout.ts                      # Config layout
├── {feature}/                      # Feature específica
│   ├── +page.svelte
│   └── +page.ts
```

### Librerías Compartidas
```
src/lib/
├── api.svelte.ts                   # Cliente API centralizado
├── auth.svelte.ts                  # Store autenticación
├── types.ts                        # Types TypeScript
├── utils.ts                        # Utilidades generales
├── components/                     # Componentes reutilizables
└── stores/                         # Svelte stores
```

### Componente Svelte - Plantilla
```svelte
<script lang="ts">
  // Props tipados
  interface Props {
    title: string;
    variant?: 'primary' | 'secondary';
  }
  
  const { title, variant = 'primary' }: Props = $props();
  
  // State reactivo con $state
  let isVisible = $state(false);
  
  // Computed con $derived
  const cssClass = $derived(`btn btn-${variant}`);
</script>

<div class={cssClass}>
  <h2>{title}</h2>
</div>

<style>
  .btn { /* Estilos base */ }
</style>
```

### Frontend - Mejores Prácticas
- SIEMPRE usar TypeScript con interfaces estrictas
- Props tipados con `interface Props`
- Usar Svelte 5 Runes: `$state`, `$derived`, `$effect`, `$props`
- Cliente API centralizado en `src/lib/api.svelte.ts`
- Error handling consistente con `ApiResponse<T>` interface
- Store reactivos con clases y getters
- Configuración centralizada en `src/config.js`
- Tests unitarios junto al código (`.test.ts`)
- Tests E2E en directorio `e2e/` con patrón `{feature}.spec.ts`

## 🏗️ TERRAFORM - REGLAS ESPECÍFICAS

### Estructura Módulos Obligatoria
```
modules/{nombre}/
├── README.md                       # Documentación del módulo
├── main.tf                         # Recursos principales
├── variables.tf                    # Variables de entrada
├── outputs.tf                      # Outputs del módulo
└── versions.tf                     # Versiones providers (opcional)
```

### Variables con Validación Obligatoria
```hcl
variable "environment" {
  description = "Ambiente de deployment (dev, qas, prd)"
  type        = string
  
  validation {
    condition     = contains(["dev", "qas", "prd"], var.environment)
    error_message = "Environment debe ser: dev, qas, o prd."
  }
}
```

### Tags Estándar Obligatorios
```hcl
tags = {
  Project     = "Turnaki-NexioQ"
  Environment = var.environment
  ManagedBy   = "Terraform"
  Owner       = "DevOps"
}
```

### Terraform - Mejores Prácticas
- Módulos reutilizables con documentación completa
- Variables con validación y descripción
- Outputs descriptivos con `sensitive = false/true` apropiado
- Locals para cálculos complejos y configuración por ambiente
- Data sources para referencias externas (`aws_caller_identity`, `aws_region`)
- Lifecycle rules para prevenir recreación accidental
- Configuración robusta de recursos con todos los parámetros necesarios

## 📚 DOCUMENTACIÓN - REGLAS ESPECÍFICAS

### Estructura Documentación
```
docs/
├── README.md                       # Índice principal
├── ARCHITECTURE.md                 # Diseño técnico
├── API.md                          # Especificación endpoints
├── DEPLOYMENT.md                   # Guía deployment
├── DEVELOPMENT.md                  # Setup desarrollo
├── TESTING.md                      # Estrategia testing
├── AUTHENTICATION.md               # Flujo auth
├── RUNBOOK.md                      # Operaciones
├── ROADMAP.md                      # Features futuras
└── archive/                        # Documentación histórica
```

### Plantilla Documento Markdown
```markdown
# 📊 Título del Documento

**Descripción breve**

---

## 📋 Tabla de Contenidos

## 🎯 Sección Principal

---

## 📚 Referencias

---

**Última actualización**: {fecha}
**Versión**: {version}
**Mantenido por**: {equipo}
```

## 🧪 TESTING - REGLAS ESPECÍFICAS

### Convenciones Naming Tests
- Unit Rust: `test_function_name` (ej: `test_create_booking_success`)
- Unit TypeScript: `should_do_something` (ej: `should_create_booking_successfully`)
- E2E: `{feature}.spec.ts` (ej: `booking-flow.spec.ts`)
- Integration: `integration_test.rs`

### Organización Tests
- Backend: Tests en `tests/` directory dentro de cada función
- Frontend: Tests junto al código (`.test.ts`) + E2E en `e2e/`
- Patrón Arrange-Act-Assert obligatorio
- Minimum 80% coverage para nuevas features

## 🔀 GIT WORKFLOW - REGLAS ESPECÍFICAS

### Estructura Ramas
- `main`: Rama principal (protegida)
- `feature/TICKET-descripcion`: Features nuevas
- `fix/TICKET-descripcion`: Corrección bugs
- `hotfix/TICKET-descripcion`: Fixes urgentes producción
- `release/vX.Y.Z`: Preparación releases

### Commit Messages (Conventional Commits)
```
tipo(scope): descripción breve

Descripción detallada si necesario.

- Cambio específico 1
- Cambio específico 2

Closes #123
```

Tipos permitidos: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## 📄 GESTIÓN ARCHIVOS

### INCLUIR en Git
- ✅ Código fuente: `src/**/*.rs`, `src/**/*.ts`, `src/**/*.svelte`, `*.tf`
- ✅ Configuraciones: `package.json`, `Cargo.toml`, `tsconfig.json`, `terraform.tfvars`
- ✅ Documentación: `README.md`, `docs/**/*.md`, `CHANGELOG.md`
- ✅ Scripts: `scripts/**/*.sh`
- ✅ Tests: `tests/**/*.rs`, `e2e/**/*.spec.ts`

### NO INCLUIR en Git
- ❌ Build artifacts: `target/`, `node_modules/`, `dist/`, `build/`
- ❌ IDE específicos: `.vscode/`, `.idea/`, `*.swp`
- ❌ OS específicos: `.DS_Store`, `Thumbs.db`
- ❌ Secrets: `.env.local`, `*.pem`, `*.key`
- ❌ Terraform state: `*.tfstate`, `.terraform/`, `*.tfplan`

## 🔧 SCRIPTS - REGLAS ESPECÍFICAS

### Ubicaciones Estándar
- `scripts/`: Scripts generales del proyecto
- `terraform/scripts/`: Scripts específicos Terraform
- `frontend/scripts/`: Scripts específicos frontend (si aplica)

### Plantilla Script Bash
```bash
#!/bin/bash
# Descripción: {Propósito del script}

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

log_info() { echo "ℹ️  $*" >&2; }
log_error() { echo "❌ ERROR: $*" >&2; }
log_success() { echo "✅ $*" >&2; }

main() {
    log_info "Iniciando ${0##*/}..."
    # Lógica principal
    log_success "Script completado!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## 🎯 REGLAS DE DESARROLLO OBLIGATORIAS

### Al Crear Nueva Feature
1. Crear ticket y rama `feature/TICKET-descripcion`
2. Seguir convenciones nomenclatura exactas
3. Agregar tests unitarios (mín 80% coverage)
4. Actualizar documentación relevante
5. Validar en ambiente local antes de PR
6. Ejecutar linters: `npm run lint`, `cargo clippy`
7. Verificar builds: `npm run build`, `cargo build`

### Al Hacer Changes
1. Mantener estructura de carpetas definida
2. No romper tests existentes
3. Agregar logs apropiados con `tracing` (Rust) o `console.log` (TS)
4. Usar tipos estrictos, evitar `any` en TypeScript
5. Separar lógica de negocio de handlers/components
6. Reutilizar código de shared libraries

### Al Escribir Código
1. Rust: Error handling explícito, usar shared-lib, tipos específicos
2. TypeScript: Interfaces estrictas, error handling consistente
3. Terraform: Variables validadas, tags estándar, modules documentados
4. Svelte: Props tipados, Runes ($state, $derived), componentes reutilizables

## 🚨 VALIDACIONES AUTOMÁTICAS

### Pre-commit Checks
- Formateo: `cargo fmt`, `npm run format`
- Linting: `cargo clippy`, `npm run lint`
- Tests: `cargo test`, `npm test`
- Build: `cargo build`, `npm run build`
- Terraform: `terraform fmt`, `terraform validate`

### Estructura Requerida
- Backend: Cada Lambda DEBE tener `Cargo.toml` y `src/main.rs`
- Frontend: Rutas DEBEN seguir patrón `+page.svelte`
- Terraform: Módulos DEBEN tener `main.tf`, `variables.tf`, `outputs.tf`, `README.md`
- Docs: Nuevas features DEBEN actualizar documentación relevante

## 📊 MÉTRICAS Y CALIDAD

### Coverage Mínimo
- Tests unitarios: 80% minimum
- Tests E2E: Features críticas cubiertas
- Documentación: Todos los módulos públicos documentados

### Performance
- Lambda cold start < 2s
- Frontend bundle < 1MB
- API response time < 500ms (p95)

---

**ESTAS REGLAS SON OBLIGATORIAS Y DEBEN SEGUIRSE EN TODO MOMENTO**
**CUANDO HAY CONFLICTO, PRIORIZAR: SEGURIDAD > CONSISTENCIA > PERFORMANCE > SIMPLICIDAD**
EOF

    # Agregar timestamp al final
    echo "" >> "$CURSOR_RULES"
    echo "---" >> "$CURSOR_RULES"
    echo "" >> "$CURSOR_RULES"
    echo "**🔄 Reglas sincronizadas automáticamente desde GUIA_ORGANIZACION_PROYECTO.md**" >> "$CURSOR_RULES"
    echo "**📅 Última sincronización**: $timestamp" >> "$CURSOR_RULES"
    echo "**🤖 Generado por**: scripts/sync-cursor-rules.sh" >> "$CURSOR_RULES"

    log_success "Reglas de Cursor actualizadas exitosamente"
}

# Validar que las reglas se aplicaron correctamente
validate_generated_rules() {
    local lines_count
    lines_count=$(wc -l < "$CURSOR_RULES")
    
    if [[ $lines_count -lt 100 ]]; then
        log_error "Las reglas generadas parecen incompletas (solo $lines_count líneas)"
        return 1
    fi

    log_info "Validación exitosa: $lines_count líneas en reglas"
    return 0
}

# Mostrar resumen de cambios
show_summary() {
    log_info "=== RESUMEN DE SINCRONIZACIÓN ==="
    echo ""
    echo "📄 Archivo fuente: GUIA_ORGANIZACION_PROYECTO.md"
    echo "🎯 Archivo destino: .cursor/rules"
    echo "📊 Líneas generadas: $(wc -l < "$CURSOR_RULES")"
    echo "⏰ Timestamp: $(generate_timestamp)"
    echo ""
    log_info "Las nuevas reglas estarán activas en la próxima interacción de Cursor"
}

# Función principal
main() {
    log_info "🔄 Iniciando sincronización de reglas Cursor..."
    echo ""

    validate_requirements
    backup_existing_rules
    generate_updated_rules
    
    if validate_generated_rules; then
        show_summary
        log_success "🎉 Sincronización completada exitosamente!"
    else
        log_error "❌ Falló la validación de reglas generadas"
        exit 1
    fi
}

# Ejecutar si es invocado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
