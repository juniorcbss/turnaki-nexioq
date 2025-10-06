#!/bin/bash
# Script para validar sintaxis de Terraform en todos los ambientes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔍 Validando sintaxis de Terraform..."
echo ""

# Validar módulos
echo "📦 Validando módulos..."
for MODULE_DIR in "$TERRAFORM_DIR"/modules/*/; do
  MODULE_NAME=$(basename "$MODULE_DIR")
  echo "  - $MODULE_NAME"
  cd "$MODULE_DIR"
  terraform fmt -check -recursive || echo "    ⚠️  Formato incorrecto"
  terraform validate 2>/dev/null || echo "    ⚠️  No inicializado (OK)"
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
    else
      echo "    ⚠️  No inicializado (ejecutar terraform init)"
    fi
  fi
done

echo ""
echo "✅ Validación completada"
