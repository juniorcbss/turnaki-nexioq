#!/usr/bin/env bash

set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
ROLE_NAME="github-actions-terraform-dev"
STATE_BUCKET="turnaki-nexioq-terraform-state"
STATE_LOCK_TABLE="turnaki-nexioq-terraform-locks"

# Args (opcionales): REPO_SLUG E2E_EMAIL E2E_PASS
REPO_SLUG_INPUT="${1:-}"
E2E_EMAIL_INPUT="${2:-${E2E_USER_EMAIL:-}}"
E2E_PASS_INPUT="${3:-${E2E_USER_PASSWORD:-}}"

log() { printf "[%s] %s\n" "$(date +"%H:%M:%S")" "$*"; }

require_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Falta comando: $1"; exit 1; }; }

require_cmd aws
require_cmd git

# gh es opcional pero recomendado para crear secrets
if ! command -v gh >/dev/null 2>&1; then
  log "⚠️  gh CLI no encontrado: no se podrán crear secrets automáticamente"
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
log "AWS Account: $ACCOUNT_ID  Region: $REGION"

# Detectar repo slug si no fue pasado como argumento
REPO_SLUG="$REPO_SLUG_INPUT"
if [ -z "$REPO_SLUG" ]; then
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    REPO_SLUG=$(gh repo view --json owner,name -q '.owner.login + "/" + .name' || true)
  fi
fi
if [ -z "$REPO_SLUG" ]; then
  REMOTE=$(git remote get-url origin)
  REPO_SLUG=$(printf "%s" "$REMOTE" | sed -E 's#.*github.com[:/]+([^/]+)/([^/.]+)(\.git)?#\1/\2#')
fi
if [ -z "$REPO_SLUG" ]; then
  echo "❌ No se pudo determinar REPO_SLUG (org/repo). Pásalo como primer argumento."
  exit 1
fi
log "GitHub Repo: $REPO_SLUG"

OIDC_ARN="arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" >/dev/null 2>&1; then
  log "✅ OIDC Provider existente"
else
  log "➕ Creando OIDC Provider"
  aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
fi

cat > trust-policy.json <<EOF
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
          "token.actions.githubusercontent.com:sub": "repo:$REPO_SLUG:*"
        }
      }
    }
  ]
}
EOF

if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  log "⚙️  Actualizando trust policy del rol $ROLE_NAME"
  aws iam update-assume-role-policy --role-name "$ROLE_NAME" --policy-document file://trust-policy.json
else
  log "➕ Creando rol $ROLE_NAME"
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file://trust-policy.json \
    --description "GitHub Actions OIDC - Terraform Dev"
fi

# Adjuntar PowerUserAccess (idempotente)
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/PowerUserAccess >/dev/null 2>&1 || true

cat > state-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject","s3:PutObject","s3:DeleteObject","s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::$STATE_BUCKET",
        "arn:aws:s3:::$STATE_BUCKET/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["dynamodb:GetItem","dynamodb:PutItem","dynamodb:DeleteItem"],
      "Resource": "arn:aws:dynamodb:$REGION:$ACCOUNT_ID:table/$STATE_LOCK_TABLE"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name TerraformStateAccess \
  --policy-document file://state-policy.json

ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
log "ROLE ARN: $ROLE_ARN"

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  log "🔐 Creando secrets en GitHub"
  gh secret set AWS_ROLE_TO_ASSUME --body "$ROLE_ARN"
  if [ -n "$E2E_EMAIL_INPUT" ]; then gh secret set E2E_USER_EMAIL --body "$E2E_EMAIL_INPUT"; fi
  if [ -n "$E2E_PASS_INPUT" ]; then gh secret set E2E_USER_PASSWORD --body "$E2E_PASS_INPUT"; fi
else
  log "⚠️  gh CLI no autenticado o ausente; omitiendo creación de secrets"
fi

log "✅ OIDC + Rol + Policies listos"

