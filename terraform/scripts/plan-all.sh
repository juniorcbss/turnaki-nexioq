#!/bin/bash
# Script para ejecutar terraform plan en todos los ambientes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔍 Ejecutando terraform plan en todos los ambientes..."
echo ""

for ENV in dev qas prd; do
  ENV_DIR="$TERRAFORM_DIR/environments/$ENV"
  
  if [ -d "$ENV_DIR" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Ambiente: $ENV"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd "$ENV_DIR"
    
    if [ ! -d ".terraform" ]; then
      echo "⚠️  No inicializado. Ejecutando terraform init..."
      terraform init
    fi
    
    terraform plan -out="tfplan-$ENV"
    
    echo ""
  fi
done

echo "✅ Plan completado para todos los ambientes"
