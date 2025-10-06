#!/bin/bash
# Script para inicializar backend de Terraform (S3 + DynamoDB)
# Ejecutar antes de terraform init

set -e

BUCKET_NAME="turnaki-nexioq-terraform-state"
DYNAMODB_TABLE="turnaki-nexioq-terraform-locks"
REGION="us-east-1"

echo "🚀 Inicializando backend de Terraform..."
echo ""

# Crear bucket S3 para tfstate
echo "📦 Creando bucket S3: $BUCKET_NAME"
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" 2>/dev/null || echo "Bucket ya existe"

# Habilitar versionado
echo "🔄 Habilitando versionado..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# Habilitar encriptación
echo "🔐 Habilitando encriptación..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Bloquear acceso público
echo "🔒 Bloqueando acceso público..."
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Crear tabla DynamoDB para locks
echo "🔐 Creando tabla DynamoDB: $DYNAMODB_TABLE"
aws dynamodb create-table \
  --table-name "$DYNAMODB_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION" 2>/dev/null || echo "Tabla ya existe"

echo ""
echo "✅ Backend inicializado exitosamente!"
echo ""
echo "Ahora puedes descomentar la sección backend en backend.tf y ejecutar:"
echo "  cd environments/dev"
echo "  terraform init"
