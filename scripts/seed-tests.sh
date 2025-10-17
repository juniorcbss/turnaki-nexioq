#!/bin/bash

set -euo pipefail

# Semillas deterministas para E2E
# Usa TZ America/Guayaquil y permite override de IDs por entorno

export TZ="America/Guayaquil"

TABLE_NAME=${TABLE_NAME:-"tk-nq-main"}
TENANT_ID=${TENANT_ID:-"tenant-demo-001"}
SITE_ID=${SITE_ID:-"site-001"}
PROF_ID=${PROF_ID:-"prof-001"}

echo "🧪 Semillando datos E2E en $TABLE_NAME (tenant=$TENANT_ID)"

NOW_ISO=${NOW_ISO:-"2025-10-01T09:00:00Z"}

TABLE_NAME="$TABLE_NAME" TENANT_ID="$TENANT_ID" SITE_ID="$SITE_ID" PROF_ID="$PROF_ID" NOW_ISO="$NOW_ISO" \
  bash "$(dirname "$0")/seed-dynamo-direct.sh"

echo "✅ Semillas E2E listas"


