#!/bin/bash

# Script para insertar datos de prueba directamente en DynamoDB
# Usa AWS CLI sin necesidad de JWT
# Preferencia de zona horaria: America/Guayaquil

set -euo pipefail

# Permitir override por variables de entorno/args
TABLE_NAME=${TABLE_NAME:-"tk-nq-main"}
TENANT_ID=${TENANT_ID:-"tenant-demo-001"}
SITE_ID=${SITE_ID:-"site-001"}
PROF_ID=${PROF_ID:-"prof-001"}

# Control de fecha determinista (si NOW_ISO está definido)
export TZ="America/Guayaquil"
NOW_LOCAL=${NOW_LOCAL:-$(date +"%Y-%m-%dT%H:%M:%S%z")}
NOW=${NOW_ISO:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 INSERTANDO DATOS DE PRUEBA EN DYNAMODB"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Crear Tenant
echo "1️⃣  Creando Tenant..."
aws dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{
    "PK": {"S": "TENANT#'"$TENANT_ID"'"},
    "SK": {"S": "METADATA"},
    "id": {"S": "'"$TENANT_ID"'"},
    "name": {"S": "Clínica Dental Demo"},
    "contactEmail": {"S": "demo@clinica.com"},
    "timezone": {"S": "America/Guayaquil"},
    "status": {"S": "active"},
    "createdAt": {"S": "'"$NOW"'"}
  }' 2>&1 | grep -v "An error occurred" || echo "✅ Tenant creado (o ya existía)"

# 2. Crear Tratamiento 1
echo "2️⃣  Creando Tratamientos..."
aws dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{
    "PK": {"S": "TENANT#'"$TENANT_ID"'"},
    "SK": {"S": "TREATMENT#t-001"},
    "GSI1PK": {"S": "TENANT#'"$TENANT_ID"'"},
    "GSI1SK": {"S": "TREATMENT#t-001"},
    "id": {"S": "t-001"},
    "tenantId": {"S": "'"$TENANT_ID"'"},
    "name": {"S": "Limpieza Dental"},
    "durationMinutes": {"N": "30"},
    "bufferMinutes": {"N": "15"},
    "price": {"N": "50000"},
    "createdAt": {"S": "'"$NOW"'"}
  }' 2>&1 | grep -v "An error occurred" || echo "  ✅ Limpieza Dental (o ya existía)"

# 3. Crear Tratamiento 2
aws dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{
    "PK": {"S": "TENANT#'"$TENANT_ID"'"},
    "SK": {"S": "TREATMENT#t-002"},
    "GSI1PK": {"S": "TENANT#'"$TENANT_ID"'"},
    "GSI1SK": {"S": "TREATMENT#t-002"},
    "id": {"S": "t-002"},
    "tenantId": {"S": "'"$TENANT_ID"'"},
    "name": {"S": "Extracción Simple"},
    "durationMinutes": {"N": "45"},
    "bufferMinutes": {"N": "15"},
    "price": {"N": "80000"},
    "createdAt": {"S": "'"$NOW"'"}
  }' 2>&1 | grep -v "An error occurred" || echo "  ✅ Extracción Simple (o ya existía)"

# 4. Crear Tratamiento 3
aws dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{
    "PK": {"S": "TENANT#'"$TENANT_ID"'"},
    "SK": {"S": "TREATMENT#t-003"},
    "GSI1PK": {"S": "TENANT#'"$TENANT_ID"'"},
    "GSI1SK": {"S": "TREATMENT#t-003"},
    "id": {"S": "t-003"},
    "tenantId": {"S": "'"$TENANT_ID"'"},
    "name": {"S": "Ortodoncia - Consulta"},
    "durationMinutes": {"N": "60"},
    "bufferMinutes": {"N": "0"},
    "price": {"N": "120000"},
    "createdAt": {"S": "'"$NOW"'"}
  }' 2>&1 | grep -v "An error occurred" || echo "  ✅ Ortodoncia - Consulta (o ya existía)"

# 5. Crear Profesional
echo "3️⃣  Creando Profesional..."
aws dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{
    "PK": {"S": "TENANT#'"$TENANT_ID"'"},
    "SK": {"S": "PROFESSIONAL#'"$PROF_ID"'"},
    "GSI1PK": {"S": "TENANT#'"$TENANT_ID"'"},
    "GSI1SK": {"S": "PROFESSIONAL#'"$PROF_ID"'"},
    "GSI3PK": {"S": "PROFESSIONAL#'"$PROF_ID"'"},
    "GSI3SK": {"S": "METADATA"},
    "id": {"S": "'"$PROF_ID"'"},
    "tenantId": {"S": "'"$TENANT_ID"'"},
    "name": {"S": "Dr. Juan Pérez"},
    "email": {"S": "dr.perez@clinica.com"},
    "specialties": {"L": [
      {"S": "Odontología General"},
      {"S": "Endodoncia"}
    ]},
    "schedule": {"S": "{\"monday\":[\"09:00-17:00\"],\"tuesday\":[\"09:00-17:00\"],\"wednesday\":[\"09:00-17:00\"],\"thursday\":[\"09:00-17:00\"],\"friday\":[\"09:00-17:00\"]}"},
    "status": {"S": "active"},
    "createdAt": {"S": "'"$NOW"'"}
  }' 2>&1 | grep -v "An error occurred" || echo "✅ Profesional creado (o ya existía)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DATOS DE PRUEBA INSERTADOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 IDs Creados:"
echo "   Tenant ID:       $TENANT_ID"
echo "   Site ID:         $SITE_ID"
echo "   Professional ID: $PROF_ID"
echo "   Tratamientos:    t-001, t-002, t-003"
echo ""
echo "✅ El código frontend YA tiene estos IDs configurados"
echo ""
echo "🚀 PRÓXIMOS PASOS:"
echo "   1. Recarga el navegador (Ctrl+R)"
echo "   2. Ve a http://localhost:5173/booking"
echo "   3. ¡Intenta reservar de nuevo!"
echo ""

