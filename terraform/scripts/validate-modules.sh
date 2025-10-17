#!/usr/bin/env bash
#
# Script de Validación de Módulos Terraform
# Verifica que todos los módulos tengan la estructura correcta
#
# Uso:
#   ./validate-modules.sh
#
# Salida:
#   - 0: Todos los módulos son válidos
#   - 1: Uno o más módulos tienen problemas

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
TOTAL_MODULES=0
VALID_MODULES=0
INVALID_MODULES=0

# Directorio base de módulos
MODULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/modules"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Validación de Módulos Terraform             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "📁 Directorio: ${MODULES_DIR}"
echo ""

# Archivos requeridos para cada módulo
REQUIRED_FILES=(
  "main.tf"
  "variables.tf"
  "outputs.tf"
  "README.md"
)

# Función para validar un módulo
validate_module() {
  local module_name=$1
  local module_path="${MODULES_DIR}/${module_name}"
  local is_valid=true
  local missing_files=()

  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "📦 Módulo: ${YELLOW}${module_name}${NC}"
  echo ""

  # Verificar que el directorio exista
  if [ ! -d "$module_path" ]; then
    echo -e "  ${RED}✗ Directorio no existe${NC}"
    return 1
  fi

  # Verificar cada archivo requerido
  for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "${module_path}/${file}" ]; then
      # Verificar que el archivo no esté vacío
      if [ -s "${module_path}/${file}" ]; then
        echo -e "  ${GREEN}✓${NC} ${file}"
      else
        echo -e "  ${RED}✗${NC} ${file} ${YELLOW}(vacío)${NC}"
        missing_files+=("$file")
        is_valid=false
      fi
    else
      echo -e "  ${RED}✗${NC} ${file} ${RED}(no existe)${NC}"
      missing_files+=("$file")
      is_valid=false
    fi
  done

  echo ""

  # Validar sintaxis básica de Terraform
  if [ -f "${module_path}/main.tf" ]; then
    cd "$module_path"
    if terraform fmt -check -diff=false main.tf variables.tf outputs.tf > /dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} Formato Terraform correcto"
    else
      echo -e "  ${YELLOW}⚠${NC} Formato Terraform necesita ajustes (ejecutar terraform fmt)"
    fi
    # Lint y seguridad si están instalados
    if command -v tflint >/dev/null 2>&1; then
      if tflint --disable-rule=terraform_required_providers; then
        echo -e "  ${GREEN}✓${NC} tflint sin hallazgos críticos"
      else
        echo -e "  ${YELLOW}⚠${NC} tflint con observaciones"
      fi
    else
      echo -e "  ${YELLOW}ℹ${NC} tflint no instalado (omitiendo)"
    fi
    if command -v tfsec >/dev/null 2>&1; then
      if tfsec --soft-fail; then
        echo -e "  ${GREEN}✓${NC} tfsec sin hallazgos críticos"
      else
        echo -e "  ${YELLOW}⚠${NC} tfsec hallazgos (soft-fail)"
      fi
    else
      echo -e "  ${YELLOW}ℹ${NC} tfsec no instalado (omitiendo)"
    fi
    cd - > /dev/null
  fi

  echo ""

  if [ "$is_valid" = true ]; then
    echo -e "  ${GREEN}✅ Módulo válido${NC}"
    ((VALID_MODULES++))
    return 0
  else
    echo -e "  ${RED}❌ Módulo inválido${NC}"
    echo -e "  ${RED}   Archivos faltantes/vacíos: ${missing_files[*]}${NC}"
    ((INVALID_MODULES++))
    return 1
  fi
}

# Obtener lista de módulos
if [ ! -d "$MODULES_DIR" ]; then
  echo -e "${RED}Error: Directorio de módulos no existe: ${MODULES_DIR}${NC}"
  exit 1
fi

MODULES=($(ls -1 "$MODULES_DIR"))

if [ ${#MODULES[@]} -eq 0 ]; then
  echo -e "${RED}Error: No se encontraron módulos en ${MODULES_DIR}${NC}"
  exit 1
fi

TOTAL_MODULES=${#MODULES[@]}

# Validar cada módulo
for module in "${MODULES[@]}"; do
  validate_module "$module"
  echo ""
done

# Resumen final
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Resumen de Validación                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Total de módulos:    ${TOTAL_MODULES}"
echo -e "  ${GREEN}Módulos válidos:     ${VALID_MODULES}${NC}"
echo -e "  ${RED}Módulos inválidos:   ${INVALID_MODULES}${NC}"
echo ""

# Porcentaje de éxito
SUCCESS_RATE=$(echo "scale=2; ($VALID_MODULES / $TOTAL_MODULES) * 100" | bc)
echo -e "  Tasa de éxito:       ${SUCCESS_RATE}%"
echo ""

# Resultado final
if [ $INVALID_MODULES -eq 0 ]; then
  echo -e "${GREEN}✅ Todos los módulos son válidos!${NC}"
  echo ""
  exit 0
else
  echo -e "${RED}❌ Algunos módulos tienen problemas. Por favor revísalos.${NC}"
  echo ""
  exit 1
fi
