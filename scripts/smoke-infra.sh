#!/bin/bash

set -euo pipefail

CLOUDFRONT_URL=${CLOUDFRONT_URL:-"https://d2rwm4uq5d71nu.cloudfront.net"}
API_BASE_URL=${API_BASE_URL:-"https://mqp7tk0dkh.execute-api.us-east-1.amazonaws.com"}
COGNITO_DOMAIN=${COGNITO_DOMAIN:-"https://turnaki-nexioq-dev-auth.auth.us-east-1.amazoncognito.com"}

echo "🔎 Smoke Infra: CloudFront"
code=$(curl -s -o /dev/null -w "%{http_code}" "$CLOUDFRONT_URL/")
echo "  / => $code"

echo "🔎 Smoke Infra: WAF via API /health"
code=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE_URL/health")
echo "  /health => $code"

echo "🔎 Smoke Infra: Cognito Hosted UI"
code=$(curl -s -o /dev/null -w "%{http_code}" "$COGNITO_DOMAIN/oauth2/authorize")
echo "  /oauth2/authorize => $code"

echo "✅ Smoke infra finalizado"


