#!/bin/bash
# Script para aplicar cambios en ambiente DEV

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$(dirname "$SCRIPT_DIR")/environments/dev"

echo "🚀 Aplicando cambios en ambiente DEV..."
echo ""

cd "$ENV_DIR"

# Verificar si existe terraform
if ! command -v terraform &> /dev/null; then
  echo "❌ Terraform no está instalado"
  exit 1
fi

# Inicializar si es necesario
if [ ! -d ".terraform" ]; then
  echo "📦 Inicializando Terraform..."
  terraform init
fi

# Plan
echo "📋 Ejecutando plan..."
terraform plan -out=tfplan

# Confirmar
echo ""
read -p "¿Aplicar estos cambios? (yes/no): " CONFIRM

if [ "$CONFIRM" = "yes" ]; then
  echo "✅ Aplicando cambios..."
  terraform apply tfplan
  rm tfplan
  echo ""
  echo "🎉 Deployment completado!"
else
  echo "❌ Deployment cancelado"
  rm tfplan
  exit 1
fi
