#!/bin/bash
# Script para destruir infraestructura DEV
# ⚠️  USAR CON PRECAUCIÓN

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$(dirname "$SCRIPT_DIR")/environments/dev"

echo "⚠️  DESTRUYENDO infraestructura DEV..."
echo ""

cd "$ENV_DIR"

if ! command -v terraform &> /dev/null; then
  echo "❌ Terraform no está instalado"
  exit 1
fi

echo "📋 Ejecutando plan de destrucción..."
terraform plan -destroy

echo ""
read -p "¿DESTRUIR todos los recursos en DEV? (yes/no): " CONFIRM

if [ "$CONFIRM" = "yes" ]; then
  echo ""
  read -p "¿Estás SEGURO? Escribe 'DESTRUIR': " CONFIRM2
  
  if [ "$CONFIRM2" = "DESTRUIR" ]; then
    echo "💥 Destruyendo infraestructura..."
    terraform destroy -auto-approve
    echo ""
    echo "✅ Infraestructura destruida"
  else
    echo "❌ Confirmación incorrecta. Operación cancelada"
    exit 1
  fi
else
  echo "❌ Operación cancelada"
  exit 1
fi
