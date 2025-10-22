#!/bin/bash

# 🔍 Script de validación de configuración CI/CD
# Proyecto: Turnaki-NexioQ
# Fecha: Octubre 2025

set -euo pipefail

echo "🔍 Validando configuración de CI/CD..."
echo "========================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

function check_command() {
  if command -v "$1" &> /dev/null; then
    echo -e "${GREEN}✅${NC} $1 está instalado"
    return 0
  else
    echo -e "${RED}❌${NC} $1 NO está instalado"
    ((ERRORS++))
    return 1
  fi
}

function check_aws_resource() {
  local resource_type="$1"
  local resource_name="$2"
  local description="$3"
  
  if aws iam get-role --role-name "$resource_name" &>/dev/null; then
    echo -e "${GREEN}✅${NC} $description existe"
    return 0
  else
    echo -e "${RED}❌${NC} $description NO existe"
    ((ERRORS++))
    return 1
  fi
}

function check_github_secret() {
  local secret_name="$1"
  local description="$2"
  
  if gh secret list 2>/dev/null | grep -q "$secret_name"; then
    echo -e "${GREEN}✅${NC} Secret $secret_name configurado"
    return 0
  else
    echo -e "${YELLOW}⚠️${NC} Secret $secret_name NO configurado"
    ((WARNINGS++))
    return 1
  fi
}

# 1. Verificar comandos necesarios
echo "1️⃣ Verificando comandos necesarios..."
check_command "aws"
check_command "terraform"
check_command "gh"
check_command "git"
echo ""

# 2. Verificar AWS CLI configurado
echo "2️⃣ Verificando configuración de AWS..."
if aws sts get-caller-identity &>/dev/null; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  CURRENT_USER=$(aws sts get-caller-identity --query Arn --output text)
  echo -e "${GREEN}✅${NC} AWS CLI configurado"
  echo "   Account ID: $ACCOUNT_ID"
  echo "   User: $CURRENT_USER"
else
  echo -e "${RED}❌${NC} AWS CLI no está configurado o no tienes permisos"
  ((ERRORS++))
fi
echo ""

# 3. Verificar GitHub CLI configurado
echo "3️⃣ Verificando configuración de GitHub..."
if gh auth status &>/dev/null; then
  GITHUB_USER=$(gh api user --jq .login)
  echo -e "${GREEN}✅${NC} GitHub CLI autenticado como: $GITHUB_USER"
else
  echo -e "${RED}❌${NC} GitHub CLI no está autenticado. Ejecuta: gh auth login"
  ((ERRORS++))
fi
echo ""

# 4. Verificar OIDC Provider
echo "4️⃣ Verificando OIDC Provider en AWS..."
OIDC_ARN="arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" &>/dev/null; then
  echo -e "${GREEN}✅${NC} OIDC Provider existe: $OIDC_ARN"
else
  echo -e "${RED}❌${NC} OIDC Provider NO existe"
  echo "   Ejecuta: ./setup-aws-oidc.sh"
  ((ERRORS++))
fi
echo ""

# 5. Verificar roles IAM
echo "5️⃣ Verificando roles IAM..."
check_aws_resource "role" "github-actions-terraform-dev" "Rol IAM para Dev/QAS"
check_aws_resource "role" "github-actions-terraform-prd" "Rol IAM para PRD"
echo ""

# 6. Obtener ARNs de roles (si existen)
echo "6️⃣ ARNs de roles configurados..."
if aws iam get-role --role-name "github-actions-terraform-dev" &>/dev/null; then
  DEV_ROLE_ARN=$(aws iam get-role --role-name "github-actions-terraform-dev" --query 'Role.Arn' --output text)
  echo "   Dev: $DEV_ROLE_ARN"
fi

if aws iam get-role --role-name "github-actions-terraform-prd" &>/dev/null; then
  PRD_ROLE_ARN=$(aws iam get-role --role-name "github-actions-terraform-prd" --query 'Role.Arn' --output text)
  echo "   Prd: $PRD_ROLE_ARN"
fi
echo ""

# 7. Verificar policies en roles
echo "7️⃣ Verificando políticas en roles..."
if aws iam get-role --role-name "github-actions-terraform-dev" &>/dev/null; then
  if aws iam list-attached-role-policies --role-name "github-actions-terraform-dev" | grep -q "PowerUserAccess"; then
    echo -e "${GREEN}✅${NC} Rol dev tiene PowerUserAccess"
  else
    echo -e "${YELLOW}⚠️${NC} Rol dev NO tiene PowerUserAccess"
    ((WARNINGS++))
  fi
  
  if aws iam get-role-policy --role-name "github-actions-terraform-dev" --policy-name "TerraformStateAccess" &>/dev/null; then
    echo -e "${GREEN}✅${NC} Rol dev tiene TerraformStateAccess"
  else
    echo -e "${YELLOW}⚠️${NC} Rol dev NO tiene TerraformStateAccess"
    ((WARNINGS++))
  fi
fi
echo ""

# 8. Verificar Terraform backend
echo "8️⃣ Verificando backend de Terraform..."
TF_BUCKET="turnaki-nexioq-terraform-state"
TF_LOCKS_TABLE="turnaki-nexioq-terraform-locks"

if aws s3api head-bucket --bucket "$TF_BUCKET" &>/dev/null; then
  echo -e "${GREEN}✅${NC} Bucket de Terraform existe: $TF_BUCKET"
else
  echo -e "${YELLOW}⚠️${NC} Bucket de Terraform NO existe: $TF_BUCKET"
  echo "   Esto es normal si es la primera vez"
  ((WARNINGS++))
fi

if aws dynamodb describe-table --table-name "$TF_LOCKS_TABLE" &>/dev/null; then
  echo -e "${GREEN}✅${NC} Tabla de locks existe: $TF_LOCKS_TABLE"
else
  echo -e "${YELLOW}⚠️${NC} Tabla de locks NO existe: $TF_LOCKS_TABLE"
  echo "   Esto es normal si es la primera vez"
  ((WARNINGS++))
fi
echo ""

# 9. Verificar GitHub Secrets
echo "9️⃣ Verificando secrets en GitHub..."
if command -v gh &> /dev/null && gh auth status &>/dev/null; then
  check_github_secret "AWS_ROLE_TO_ASSUME" "Secret principal de AWS"
  check_github_secret "AWS_ROLE_TO_ASSUME_PRD" "Secret de AWS para PRD"
else
  echo -e "${YELLOW}⚠️${NC} GitHub CLI no disponible, verifica manualmente"
  ((WARNINGS++))
fi
echo ""

# 10. Verificar GitHub Environments
echo "🔟 Verificando environments en GitHub..."
if command -v gh &> /dev/null && gh auth status &>/dev/null; then
  # Los environments no se pueden verificar vía API fácilmente
  echo -e "${YELLOW}⚠️${NC} Verifica manualmente que existen environments: dev, qas, prd"
  echo "   Settings → Environments en GitHub UI"
  ((WARNINGS++))
else
  echo -e "${YELLOW}⚠️${NC} GitHub CLI no disponible"
  ((WARNINGS++))
fi
echo ""

# 11. Verificar workflows de GitHub Actions
echo "1️⃣1️⃣ Verificando workflows en GitHub Actions..."
if [ -d ".github/workflows" ]; then
  WORKFLOW_COUNT=$(find .github/workflows -name "*.yml" -o -name "*.yaml" | wc -l | tr -d ' ')
  echo -e "${GREEN}✅${NC} Se encontraron $WORKFLOW_COUNT workflows"
else
  echo -e "${RED}❌${NC} Directorio .github/workflows no existe"
  ((ERRORS++))
fi
echo ""

# Resumen
echo "========================================"
echo "📊 RESUMEN DE VALIDACIÓN"
echo "========================================"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✅${NC} Todo está configurado correctamente"
  echo ""
  echo "🚀 Puedes proceder con la ejecución de workflows"
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}⚠️${NC} Configuración básica OK, pero hay $WARNINGS advertencias"
  echo ""
  echo "📝 Próximos pasos recomendados:"
  echo "   1. Configurar secrets faltantes en GitHub"
  echo "   2. Crear environments en GitHub UI"
  echo "   3. Verificar permisos de roles IAM"
  exit 0
else
  echo -e "${RED}❌${NC} Se encontraron $ERRORS errores y $WARNINGS advertencias"
  echo ""
  echo "📝 Pasos para corregir:"
  echo "   1. Instala comandos faltantes (aws, terraform, gh)"
  echo "   2. Configura AWS CLI: aws configure"
  echo "   3. Autentica GitHub CLI: gh auth login"
  echo "   4. Ejecuta setup de OIDC: ./setup-aws-oidc.sh"
  exit 1
fi

