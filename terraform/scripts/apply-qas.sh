#!/bin/bash
# Script para aplicar cambios en ambiente QAS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$(dirname "$SCRIPT_DIR")/environments/qas"

echo "🚀 Aplicando cambios en ambiente QAS..."
echo ""

cd "$ENV_DIR"

if ! command -v terraform &> /dev/null; then
  echo "❌ Terraform no está instalado"
  exit 1
fi

if [ ! -d ".terraform" ]; then
  echo "📦 Inicializando Terraform..."
  terraform init
fi

echo "📋 Ejecutando plan..."
terraform plan -out=tfplan

echo ""
read -p "¿Aplicar estos cambios en QAS? (yes/no): " CONFIRM

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
