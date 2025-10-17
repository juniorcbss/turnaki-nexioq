#!/bin/bash

set -euo pipefail

API_BASE_URL=${API_BASE_URL:-"https://mqp7tk0dkh.execute-api.us-east-1.amazonaws.com"}

echo "Probando payloads bloqueados por WAF..."

payloads=(
  "' OR '1'='1" # SQLi
  "<script>alert(1)</script>" # XSS
  "../../etc/passwd" # Path Traversal
)

for p in "${payloads[@]}"; do
  code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_BASE_URL/booking/availability" \
    -H 'Content-Type: application/json' \
    --data "{\"site_id\":\"site-001\",\"professional_id\":\"prof-001\",\"treatment_id\":\"t-001\",\"start_date\":\"2025-10-10\",\"end_date\":\"2025-10-17\",\"note\":\"$p\"}")
  echo "Payload: $p => HTTP $code"
done

echo "Listo. Verifique en CloudWatch los bloqueos del WAF."


