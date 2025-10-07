#!/bin/bash

# 🔐 Script para configurar AWS OIDC para GitHub Actions
# Proyecto: Turnaki-NexioQ
# Fecha: 6 de Octubre 2025

set -e  # Salir si hay errores

echo "🚀 Configurando AWS OIDC para GitHub Actions..."
echo "=================================================="

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI no está instalado. Por favor instálalo primero:"
    echo "   brew install awscli"
    exit 1
fi

# Obtener información de la cuenta
echo "📋 Obteniendo información de la cuenta AWS..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
CURRENT_USER=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null || echo "")

if [ -z "$ACCOUNT_ID" ]; then
    echo "❌ No se pudo obtener información de AWS. Verifica que:"
    echo "   1. AWS CLI esté configurado: aws configure"
    echo "   2. Tengas permisos IAM"
    exit 1
fi

echo "✅ Account ID: $ACCOUNT_ID"
echo "✅ User: $CURRENT_USER"
echo ""

# Solicitar información del repositorio GitHub
read -p "📝 Ingresa tu usuario/organización de GitHub: " GITHUB_ORG
if [ -z "$GITHUB_ORG" ]; then
    echo "❌ Usuario de GitHub es requerido"
    exit 1
fi

REPO_NAME="turnaki-nexioq"
echo "📝 Repositorio: $GITHUB_ORG/$REPO_NAME"
echo ""

# 1. Crear OIDC Provider (si no existe)
echo "1️⃣ Creando OIDC Provider..."
OIDC_ARN="arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"

if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" &>/dev/null; then
    echo "✅ OIDC Provider ya existe: $OIDC_ARN"
else
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
    echo "✅ OIDC Provider creado: $OIDC_ARN"
fi

# 2. Crear trust policy
echo ""
echo "2️⃣ Creando trust policy..."
TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:$GITHUB_ORG/$REPO_NAME:*"
        }
      }
    }
  ]
}
EOF
)

echo "$TRUST_POLICY" > trust-policy-temp.json
echo "✅ Trust policy creada"

# 3. Crear rol IAM para dev/qas
ROLE_NAME="github-actions-terraform-dev"
echo ""
echo "3️⃣ Creando rol IAM: $ROLE_NAME..."

if aws iam get-role --role-name "$ROLE_NAME" &>/dev/null; then
    echo "⚠️  Rol $ROLE_NAME ya existe. Actualizando trust policy..."
    aws iam update-assume-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-document file://trust-policy-temp.json
else
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document file://trust-policy-temp.json \
        --description "Rol para GitHub Actions - Terraform Dev/QAS"
    echo "✅ Rol $ROLE_NAME creado"
fi

# 4. Adjuntar políticas básicas
echo ""
echo "4️⃣ Adjuntando políticas..."

# PowerUserAccess para operaciones generales
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/PowerUserAccess" || echo "⚠️ Política PowerUserAccess ya adjuntada"

# 5. Crear política personalizada para Terraform State
echo ""
echo "5️⃣ Creando política para Terraform State..."

STATE_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::tk-nq-backups-tfstate",
        "arn:aws:s3:::tk-nq-backups-tfstate/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:$ACCOUNT_ID:table/tk-nq-tfstate-lock"
    }
  ]
}
EOF
)

echo "$STATE_POLICY" > state-policy-temp.json

aws iam put-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name "TerraformStateAccess" \
    --policy-document file://state-policy-temp.json

echo "✅ Política TerraformStateAccess creada"

# 6. Obtener ARN del rol
echo ""
echo "6️⃣ Obteniendo ARN del rol..."
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
echo "✅ Rol ARN: $ROLE_ARN"

# 7. Limpiar archivos temporales
rm -f trust-policy-temp.json state-policy-temp.json

# 8. Crear rol para producción (más restrictivo)
ROLE_NAME_PRD="github-actions-terraform-prd"
echo ""
echo "7️⃣ Creando rol de producción: $ROLE_NAME_PRD..."

if aws iam get-role --role-name "$ROLE_NAME_PRD" &>/dev/null; then
    echo "⚠️  Rol $ROLE_NAME_PRD ya existe"
    ROLE_ARN_PRD=$(aws iam get-role --role-name "$ROLE_NAME_PRD" --query 'Role.Arn' --output text)
else
    # Trust policy para PRD (más restrictivo - solo main branch)
    TRUST_POLICY_PRD=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:$GITHUB_ORG/$REPO_NAME:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF
)
    
    echo "$TRUST_POLICY_PRD" > trust-policy-prd-temp.json
    
    aws iam create-role \
        --role-name "$ROLE_NAME_PRD" \
        --assume-role-policy-document file://trust-policy-prd-temp.json \
        --description "Rol para GitHub Actions - Terraform Producción (solo main)"
    
    # Políticas más restrictivas para PRD
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME_PRD" \
        --policy-arn "arn:aws:iam::aws:policy/PowerUserAccess"
    
    ROLE_ARN_PRD=$(aws iam get-role --role-name "$ROLE_NAME_PRD" --query 'Role.Arn' --output text)
    rm -f trust-policy-prd-temp.json
    
    echo "✅ Rol $ROLE_NAME_PRD creado"
fi

# Resumen final
echo ""
echo "🎉 ¡Configuración de AWS OIDC completada!"
echo "=========================================="
echo ""
echo "📝 SECRETS PARA GITHUB:"
echo "   AWS_ROLE_TO_ASSUME     = $ROLE_ARN"
echo "   AWS_ROLE_TO_ASSUME_PRD = $ROLE_ARN_PRD"
echo ""
echo "🔧 PRÓXIMOS PASOS:"
echo "   1. Ve a: https://github.com/$GITHUB_ORG/$REPO_NAME/settings/secrets/actions"
echo "   2. Agrega los secrets listados arriba"
echo "   3. Crea environments (dev, qas, prd) con required reviewers"
echo "   4. Ejecuta un workflow de prueba"
echo ""
echo "📚 Documentación:"
echo "   - PROXIMOS_PASOS_PRIORITARIOS.md (Paso 3 y 4)"
echo "   - .github/SECRETS_SETUP.md"
echo ""
echo "✅ AWS OIDC configurado correctamente"

# Opcional: Configurar secrets automáticamente si gh CLI está disponible
if command -v gh &> /dev/null; then
    echo ""
    read -p "🤖 ¿Quieres que configure los secrets automáticamente con gh CLI? (y/n): " CONFIGURE_SECRETS
    if [ "$CONFIGURE_SECRETS" = "y" ] || [ "$CONFIGURE_SECRETS" = "Y" ]; then
        echo "🔑 Configurando secrets con gh CLI..."
        
        # Verificar que estemos en el directorio del repo
        if [ ! -d ".git" ]; then
            echo "❌ No estamos en un directorio git. Navega al directorio del proyecto."
            exit 1
        fi
        
        # Verificar autenticación
        if ! gh auth status &>/dev/null; then
            echo "🔐 Autenticándote con GitHub..."
            gh auth login
        fi
        
        # Configurar secrets
        echo "$ROLE_ARN" | gh secret set AWS_ROLE_TO_ASSUME
        echo "$ROLE_ARN_PRD" | gh secret set AWS_ROLE_TO_ASSUME_PRD
        
        echo "✅ Secrets configurados automáticamente"
        
        # Listar secrets para verificar
        echo ""
        echo "📋 Secrets configurados:"
        gh secret list
    else
        echo "⚠️  Configura los secrets manualmente en GitHub"
    fi
fi

echo ""
echo "🚀 ¡Listo para CI/CD!"
