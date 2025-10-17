#!/bin/bash

set -euo pipefail

USER_POOL_ID=${USER_POOL_ID:-""}
EMAIL=${E2E_USER_EMAIL:-""}
PASSWORD=${E2E_USER_PASSWORD:-""}

if [ -z "$USER_POOL_ID" ] || [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
  echo "Uso: USER_POOL_ID=... E2E_USER_EMAIL=... E2E_USER_PASSWORD=... bash scripts/create-cognito-test-user.sh"
  exit 1
fi

echo "👤 Creando usuario de pruebas en Cognito: $EMAIL"

aws cognito-idp admin-create-user \
  --user-pool-id "$USER_POOL_ID" \
  --username "$EMAIL" \
  --user-attributes Name=email,Value="$EMAIL" Name=email_verified,Value=true \
  --message-action SUPPRESS 2>/dev/null || echo "Usuario ya existe"

aws cognito-idp admin-set-user-password \
  --user-pool-id "$USER_POOL_ID" \
  --username "$EMAIL" \
  --password "$PASSWORD" \
  --permanent

echo "✅ Usuario de pruebas preparado"


