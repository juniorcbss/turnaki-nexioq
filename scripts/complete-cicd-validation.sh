#!/bin/bash

# 🧪 Script de validación completa del CI/CD
# Proyecto: Turnaki-NexioQ
# Propósito: Validar workflows y health checks después de crear environments

set -euo pipefail

echo "🧪 Validación Completa del CI/CD"
echo "=================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar que estamos en un repo git
if [ ! -d ".git" ]; then
  echo -e "${RED}❌ No estamos en un directorio git${NC}"
  exit 1
fi

# Verificar comandos necesarios
for cmd in git gh aws curl; do
  if ! command -v "$cmd" &> /dev/null; then
    echo -e "${RED}❌ $cmd no está instalado${NC}"
    exit 1
  fi
done

echo -e "${GREEN}✅ Comandos necesarios instalados${NC}"
echo ""

# Paso 1: Verificar que GitHub CLI está autenticado
echo "1️⃣ Verificando autenticación de GitHub..."
if ! gh auth status &>/dev/null; then
  echo -e "${RED}❌ GitHub CLI no está autenticado${NC}"
  echo "   Ejecuta: gh auth login"
  exit 1
fi
echo -e "${GREEN}✅ GitHub CLI autenticado${NC}"
echo ""

# Paso 2: Verificar que los environments existen
echo "2️⃣ Verificando environments en GitHub..."
ENVIRONMENTS=("dev" "qas" "prd")
for env in "${ENVIRONMENTS[@]}"; do
  if gh api "repos/:owner/:repo/environments/$env" &>/dev/null; then
    echo -e "${GREEN}✅ Environment $env existe${NC}"
  else
    echo -e "${YELLOW}⚠️  Environment $env NO existe${NC}"
    echo "   Créalo en: Settings → Environments"
  fi
done
echo ""

# Paso 3: Push de commits pendientes
echo "3️⃣ Verificando commits pendientes..."
if git status | grep -q "ahead of"; then
  AHEAD=$(git status | grep "ahead of" | grep -oE '[0-9]+')
  echo -e "${YELLOW}⚠️  Hay $AHEAD commits pendientes de push${NC}"
  read -p "¿Hacer push ahora? (y/n): " DO_PUSH
  if [ "$DO_PUSH" = "y" ] || [ "$DO_PUSH" = "Y" ]; then
    echo "Haciendo push..."
    git push origin main
    echo -e "${GREEN}✅ Push completado${NC}"
  else
    echo -e "${YELLOW}⚠️  Push cancelado. Ejecuta manualmente: git push origin main${NC}"
  fi
else
  echo -e "${GREEN}✅ Repositorio sincronizado${NC}"
fi
echo ""

# Paso 4: Crear PR de prueba
echo "4️⃣ Creando PR de prueba para validar workflows..."
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" = "main" ]; then
  TEST_BRANCH="test/cicd-validation-$(date +%s)"
  echo "Creando branch: $TEST_BRANCH"
  
  git checkout -b "$TEST_BRANCH"
  
  # Hacer un cambio menor
  echo "" >> terraform/README.md
  echo "<!-- Test de CI/CD - $(date) -->" >> terraform/README.md
  
  git add terraform/README.md
  git commit -m "test: validar workflow terraform-plan"
  
  git push origin "$TEST_BRANCH"
  
  echo ""
  echo -e "${GREEN}✅ Branch $TEST_BRANCH creado y pusheado${NC}"
  echo ""
  
  # Crear PR
  echo "Creando PR..."
  PR_URL=$(gh pr create \
    --title "Test CI/CD Activation" \
    --body "## Validación de CI/CD

Este PR está diseñado para validar que los workflows de CI/CD funcionan correctamente.

### Checklist de validación:
- [ ] Workflow terraform-plan se ejecuta automáticamente
- [ ] Comentario con plan aparece en el PR
- [ ] Plan muestra cambios esperados
- [ ] No hay errores de autenticación

### Después de validar:
Una vez que se confirme que el plan es correcto, este PR puede ser mergeado para activar el deployment automático en dev.
" \
    --base main)
  
  echo ""
  echo -e "${GREEN}✅ PR creado: $PR_URL${NC}"
  echo ""
  
  # Esperar y verificar workflow
  echo "Esperando que el workflow terraform-plan se ejecute..."
  sleep 5
  
  echo ""
  echo "📋 Verificando workflows..."
  gh run list --workflow=terraform-plan.yml --limit 5
  
  echo ""
  echo -e "${GREEN}✅ PR creado exitosamente${NC}"
  echo ""
  echo "🔍 Próximos pasos:"
  echo "   1. Monitorea el workflow en: $PR_URL"
  echo "   2. Verifica que terraform-plan se ejecuta sin errores"
  echo "   3. Revisa el comentario con el plan en el PR"
  echo "   4. Si todo está bien, haz merge del PR"
  echo "   5. Esto activará terraform-apply-dev automáticamente"
  
else
  echo -e "${YELLOW}⚠️  Ya estás en un branch: $CURRENT_BRANCH${NC}"
  echo "   Branch actual: $CURRENT_BRANCH"
fi

echo ""
echo "=================================="
echo "🎉 Validación iniciada"
echo "=================================="
echo ""
echo "📊 Para monitorear workflows:"
echo "   gh run list --workflow=terraform-plan.yml"
echo "   gh run watch"
echo ""
echo "🔗 Ver PR creado:"
echo "   gh pr list"
echo ""

