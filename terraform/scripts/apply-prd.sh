#!/bin/bash
# Script para aplicar cambios en ambiente PRD
# ⚠️  USAR CON PRECAUCIÓN - PRODUCCIÓN

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$(dirname "$SCRIPT_DIR")/environments/prd"

echo "⚠️  ⚠️  ⚠️  PRODUCCIÓN ⚠️  ⚠️  ⚠️"
echo ""
echo "🚀 Aplicando cambios en ambiente PRODUCCIÓN..."
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
echo "⚠️  ATENCIÓN: Estás a punto de modificar PRODUCCIÓN"
read -p "¿Aplicar estos cambios en PRODUCCIÓN? (yes/no): " CONFIRM

if [ "$CONFIRM" = "yes" ]; then
  echo ""
  read -p "¿Estás SEGURO? Escribe 'APLICAR PRODUCCION': " CONFIRM2
  
  if [ "$CONFIRM2" = "APLICAR PRODUCCION" ]; then
    echo "✅ Aplicando cambios en producción..."
    terraform apply tfplan
    rm tfplan
    echo ""
    echo "🎉 Deployment completado en PRODUCCIÓN!"
  else
    echo "❌ Confirmación incorrecta. Deployment cancelado"
    rm tfplan
    exit 1
  fi
else
  echo "❌ Deployment cancelado"
  rm tfplan
  exit 1
fi
