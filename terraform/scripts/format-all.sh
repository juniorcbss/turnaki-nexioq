#!/bin/bash
# Script para formatear todos los archivos Terraform

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

echo "🎨 Formateando archivos Terraform..."
echo ""

cd "$TERRAFORM_DIR"

terraform fmt -recursive

echo ""
echo "✅ Formato aplicado exitosamente"
