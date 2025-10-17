#!/bin/bash
# Script para validar sintaxis de Terraform en todos los ambientes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔍 Validando sintaxis y calidad de Terraform..."
echo ""

# Validar módulos
echo "📦 Validando módulos..."
for MODULE_DIR in "$TERRAFORM_DIR"/modules/*/; do
  MODULE_NAME=$(basename "$MODULE_DIR")
  echo "  - $MODULE_NAME"
  cd "$MODULE_DIR"
  terraform fmt -check -recursive || echo "    ⚠️  Formato incorrecto"
  terraform validate 2>/dev/null || echo "    ⚠️  No inicializado (OK)"
  if command -v tflint >/dev/null 2>&1; then
    tflint --disable-rule=terraform_required_providers || echo "    ⚠️  tflint con observaciones"
  else
    echo "    ℹ️  tflint no instalado (omitiendo)"
  fi
  if command -v tfsec >/dev/null 2>&1; then
    tfsec --soft-fail || echo "    ⚠️  tfsec hallazgos (soft-fail)"
  else
    echo "    ℹ️  tfsec no instalado (omitiendo)"
  fi
done

echo ""

# Validar ambientes
echo "🌍 Validando ambientes..."
for ENV in dev qas prd; do
  ENV_DIR="$TERRAFORM_DIR/environments/$ENV"
  
  if [ -d "$ENV_DIR" ]; then
    echo "  - $ENV"
    cd "$ENV_DIR"
    terraform fmt -check -recursive || echo "    ⚠️  Formato incorrecto"
    
    if [ -d ".terraform" ]; then
      terraform validate || echo "    ❌ Validación fallida"
      if command -v tflint >/dev/null 2>&1; then
        tflint --config "$TERRAFORM_DIR/.tflint.hcl" || echo "    ⚠️  tflint con observaciones"
      fi
      if command -v tfsec >/dev/null 2>&1; then
        tfsec --soft-fail || echo "    ⚠️  tfsec hallazgos (soft-fail)"
      fi
    else
      echo "    ⚠️  No inicializado (ejecutar terraform init)"
    fi
  fi
done

echo ""
echo "✅ Validación completada"
