#!/bin/bash

set -euo pipefail

TARGET_URL=${TARGET_URL:-"https://d2rwm4uq5d71nu.cloudfront.net"}
REPORT_DIR=${REPORT_DIR:-"./zap-report"}

mkdir -p "$REPORT_DIR"

docker run --rm -u root -v "$(pwd):/zap/wrk" -t owasp/zap2docker-stable \
  zap-baseline.py -t "$TARGET_URL" -g gen.conf -r "$REPORT_DIR/index.html" -J "$REPORT_DIR/report.json" \
  -m 5 -I || true

echo "ZAP baseline finalizado. Reporte en $REPORT_DIR"


