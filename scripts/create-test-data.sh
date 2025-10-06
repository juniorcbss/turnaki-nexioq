#!/bin/bash

# Script para crear datos de prueba en DynamoDB
# Uso: ./scripts/create-test-data.sh YOUR_JWT_TOKEN

set -e

API_BASE="https://x292iexx8a.execute-api.us-east-1.amazonaws.com"
JWT_TOKEN="${1:-}"

if [ -z "$JWT_TOKEN" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔑 OBTENER JWT TOKEN"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "1. Abre el navegador en: http://localhost:5173"
  echo "2. Haz login con Cognito"
  echo "3. Abre DevTools (F12) > Application > Local Storage"
  echo "4. Busca la clave 'token' y copia el valor"
  echo "5. Ejecuta: ./scripts/create-test-data.sh 'TU_TOKEN_AQUI'"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 CREANDO DATOS DE PRUEBA EN DYNAMODB"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Crear Tenant
echo "1️⃣  Creando Tenant (Clínica)..."
TENANT_RESPONSE=$(curl -s -X POST "$API_BASE/tenants" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Clínica Dental Demo",
    "contact_email": "demo@clinica.com",
    "timezone": "America/Guayaquil"
  }')

echo "$TENANT_RESPONSE" | jq . 2>/dev/null || echo "$TENANT_RESPONSE"
TENANT_ID=$(echo "$TENANT_RESPONSE" | jq -r '.id' 2>/dev/null || echo "demo-tenant-123")
echo "✅ Tenant ID: $TENANT_ID"
echo ""

# 2. Crear Tratamientos
echo "2️⃣  Creando Tratamientos..."
curl -s -X POST "$API_BASE/treatments" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"tenant_id\": \"$TENANT_ID\",
    \"name\": \"Limpieza Dental\",
    \"duration_minutes\": 30,
    \"buffer_minutes\": 15,
    \"price\": 50000
  }" | jq . 2>/dev/null || echo "❌ Error"

curl -s -X POST "$API_BASE/treatments" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"tenant_id\": \"$TENANT_ID\",
    \"name\": \"Extracción Simple\",
    \"duration_minutes\": 45,
    \"buffer_minutes\": 15,
    \"price\": 80000
  }" | jq . 2>/dev/null || echo "❌ Error"

curl -s -X POST "$API_BASE/treatments" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"tenant_id\": \"$TENANT_ID\",
    \"name\": \"Ortodoncia - Consulta\",
    \"duration_minutes\": 60,
    \"buffer_minutes\": 0,
    \"price\": 120000
  }" | jq . 2>/dev/null || echo "❌ Error"

echo "✅ Tratamientos creados"
echo ""

# 3. Crear Profesional
echo "3️⃣  Creando Profesional..."
PROF_RESPONSE=$(curl -s -X POST "$API_BASE/professionals" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"tenant_id\": \"$TENANT_ID\",
    \"name\": \"Dr. Juan Pérez\",
    \"email\": \"dr.perez@clinica.com\",
    \"specialties\": [\"Odontología General\", \"Endodoncia\"],
    \"schedule\": \"{\\\"monday\\\":[\\\"09:00-17:00\\\"],\\\"tuesday\\\":[\\\"09:00-17:00\\\"],\\\"wednesday\\\":[\\\"09:00-17:00\\\"],\\\"thursday\\\":[\\\"09:00-17:00\\\"],\\\"friday\\\":[\\\"09:00-17:00\\\"]}\"
  }")

echo "$PROF_RESPONSE" | jq . 2>/dev/null || echo "$PROF_RESPONSE"
PROF_ID=$(echo "$PROF_RESPONSE" | jq -r '.id' 2>/dev/null || echo "prof-001")
echo "✅ Profesional ID: $PROF_ID"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DATOS DE PRUEBA CREADOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 IDs Generados:"
echo "   Tenant ID:       $TENANT_ID"
echo "   Professional ID: $PROF_ID"
echo "   Site ID:         site-001 (hardcoded)"
echo ""
echo "🔧 ACTUALIZAR EN EL FRONTEND:"
echo ""
echo "   Edita: frontend/src/routes/booking/+page.svelte"
echo "   Cambia las líneas 27-29:"
echo ""
echo "   const MOCK_TENANT_ID = '$TENANT_ID';"
echo "   const MOCK_SITE_ID = 'site-001';"
echo "   const MOCK_PROFESSIONAL_ID = '$PROF_ID';"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 PRÓXIMOS PASOS:"
echo "   1. Actualiza los IDs en booking/+page.svelte"
echo "   2. Recarga el navegador (Ctrl+R)"
echo "   3. Intenta reservar de nuevo"
echo ""
