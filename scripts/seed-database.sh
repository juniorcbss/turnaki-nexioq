#!/bin/bash
set -e

API_URL=$(aws cloudformation describe-stacks --stack-name DevStack \
  --query "Stacks[0].Outputs[?OutputKey=='HttpApiUrl'].OutputValue" --output text)

echo "API URL: $API_URL"
echo "⚠️  Necesitas un token JWT de Cognito para crear datos"
echo ""
echo "Obtén token en:"
aws cloudformation describe-stacks --stack-name AuthStack \
  --query "Stacks[0].Outputs[?OutputKey=='HostedUIDomain'].OutputValue" --output text

echo ""
echo "Luego ejecuta:"
echo "export TOKEN=<tu-id-token>"
echo "curl -X POST $API_URL/tenants -H \"Authorization: Bearer \$TOKEN\" -H \"Content-Type: application/json\" -d '{\"name\":\"Clínica Sonrisas\",\"contact_email\":\"admin@sonrisas.com\",\"timezone\":\"America/Guayaquil\"}'"
