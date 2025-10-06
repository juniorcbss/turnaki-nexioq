# Módulo S3 + CloudFront - Frontend Hosting

## Descripción

Este módulo crea un bucket S3 privado con una distribución CloudFront (CDN) para hosting de aplicaciones web SPA (Single Page Application) con soporte para routing del lado del cliente.

## Características

- ✅ Bucket S3 privado (no acceso público directo)
- ✅ CloudFront con Origin Access Identity (OAI)
- ✅ Distribución global con baja latencia
- ✅ HTTPS obligatorio (redirect-to-https)
- ✅ Compresión automática
- ✅ SPA routing (404/403 → index.html)
- ✅ Versionado opcional
- ✅ Website configuration

## Uso

```hcl
module "frontend" {
  source = "../../modules/s3-cloudfront"

  project_name      = "turnaki-nexioq"
  environment       = "dev"
  enable_versioning = false
  price_class       = "PriceClass_100"

  tags = {
    ManagedBy = "Terraform"
    Module    = "Frontend"
  }
}
```

## Variables

| Variable | Tipo | Descripción | Default | Requerido |
|----------|------|-------------|---------|-----------|
| `project_name` | string | Nombre del proyecto | - | ✅ |
| `environment` | string | Ambiente (dev, qas, prd) | - | ✅ |
| `enable_versioning` | bool | Habilitar versionado S3 | `false` | ❌ |
| `price_class` | string | Clase de precio CloudFront | `PriceClass_100` | ❌ |
| `tags` | map(string) | Tags adicionales | `{}` | ❌ |

## Outputs

| Output | Descripción |
|--------|-------------|
| `bucket_name` | Nombre del bucket S3 |
| `bucket_arn` | ARN del bucket S3 |
| `cloudfront_domain_name` | Domain name de CloudFront |
| `cloudfront_distribution_id` | ID de la distribución |
| `cloudfront_url` | URL completa HTTPS |

## Price Classes de CloudFront

| Price Class | Regiones | Uso |
|-------------|----------|-----|
| `PriceClass_100` | NA, EU | Dev/QAS |
| `PriceClass_200` | NA, EU, Asia, África | QAS/PRD |
| `PriceClass_All` | Todas las regiones | PRD Global |

## SPA Routing

### Configuración

El módulo redirige automáticamente errores 403/404 a `index.html` para soportar client-side routing:

```
/app → 404 → /index.html ✅
/booking → 404 → /index.html ✅
/admin → 404 → /index.html ✅
```

Esto permite que frameworks como Svelte, React o Vue manejen las rutas.

## Deploy del Frontend

### Build y Upload

```bash
# 1. Build frontend
cd frontend
npm run build
# Output: frontend/build/

# 2. Sync a S3
aws s3 sync build/ s3://turnaki-nexioq-dev-frontend/ --delete

# 3. Invalidar caché CloudFront
aws cloudfront create-invalidation \
  --distribution-id E1234ABCDEFGH \
  --paths "/*"
```

### Script Automatizado

```bash
#!/bin/bash
# deploy-frontend.sh

set -e

ENVIRONMENT=${1:-dev}
BUCKET_NAME="turnaki-nexioq-${ENVIRONMENT}-frontend"
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)

echo "📦 Building frontend..."
cd frontend
npm run build

echo "☁️  Uploading to S3..."
aws s3 sync build/ s3://${BUCKET_NAME}/ \
  --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "*.html" \
  --exclude "manifest.json"

# HTML sin cache (para updates inmediatos)
aws s3 sync build/ s3://${BUCKET_NAME}/ \
  --exclude "*" \
  --include "*.html" \
  --include "manifest.json" \
  --cache-control "public, max-age=0, must-revalidate"

echo "🔄 Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id ${DISTRIBUTION_ID} \
  --paths "/*"

echo "✅ Deploy completed!"
echo "🌐 URL: https://${DISTRIBUTION_ID}.cloudfront.net"
```

## Ejemplo Completo

```hcl
module "frontend" {
  source = "../../modules/s3-cloudfront"

  project_name      = "turnaki-nexioq"
  environment       = "prd"
  enable_versioning = true   # Activar en PRD
  price_class       = "PriceClass_200"  # Más cobertura en PRD

  tags = {
    Environment = "Production"
    Application = "Frontend"
    ManagedBy   = "Terraform"
  }
}

# Output para CI/CD
output "frontend_bucket" {
  value       = module.frontend.bucket_name
  description = "Bucket S3 para deploy"
}

output "frontend_url" {
  value       = module.frontend.cloudfront_url
  description = "URL pública del frontend"
}

output "distribution_id" {
  value       = module.frontend.cloudfront_distribution_id
  description = "ID para invalidaciones"
  sensitive   = false
}
```

## Configuración de Caché

### Por Tipo de Archivo

| Tipo | Cache-Control | TTL |
|------|---------------|-----|
| HTML | `max-age=0, must-revalidate` | 0s (sin cache) |
| JS/CSS | `max-age=31536000, immutable` | 1 año |
| Imágenes | `max-age=86400` | 1 día |
| Fonts | `max-age=31536000, immutable` | 1 año |

### CloudFront TTL

- **Min TTL**: 0
- **Default TTL**: 3600 (1 hora)
- **Max TTL**: 86400 (1 día)

## Custom Domain (Opcional)

Para usar un dominio custom:

```hcl
# 1. Crear certificado ACM en us-east-1
resource "aws_acm_certificate" "frontend" {
  provider          = aws.us-east-1  # DEBE ser us-east-1 para CloudFront
  domain_name       = "app.turnaki.nexioq.com"
  validation_method = "DNS"
}

# 2. Modificar módulo S3-CloudFront
# En main.tf del módulo, agregar:
# viewer_certificate {
#   acm_certificate_arn = var.certificate_arn
#   ssl_support_method  = "sni-only"
# }
# aliases = var.domain_aliases

# 3. Crear registro DNS
resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.turnaki.nexioq.com"
  type    = "A"

  alias {
    name                   = module.frontend.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2"  # CloudFront Hosted Zone ID
    evaluate_target_health = false
  }
}
```

## Seguridad

### Configuración Actual

- ✅ Bucket privado (block all public access)
- ✅ Acceso solo vía CloudFront (OAI)
- ✅ HTTPS obligatorio
- ✅ Bucket policy restrictiva
- ❌ WAF (agregar en PRD)
- ❌ Custom domain con ACM

### Recomendaciones PRD

```hcl
# Agregar WAF
resource "aws_wafv2_web_acl_association" "frontend" {
  resource_arn = module.frontend.cloudfront_arn
  web_acl_arn  = module.waf.web_acl_arn
}

# Habilitar logging
resource "aws_cloudfront_logging_config" "main" {
  distribution_id = module.frontend.cloudfront_distribution_id
  bucket          = aws_s3_bucket.logs.bucket_domain_name
  prefix          = "cloudfront/"
}
```

## Convenciones de Nombres

```
Bucket: {project_name}-{environment}-frontend
OAI: OAI for {project_name}-{environment}
```

**Ejemplos**:
- Bucket: `turnaki-nexioq-dev-frontend`
- OAI Comment: `OAI for turnaki-nexioq-dev`

## Costos Estimados

### S3

- **Storage**: $0.023/GB (primeros 50TB)
- **Requests GET**: $0.0004/1K requests
- **Transfer OUT**: Gratis a CloudFront

### CloudFront (PriceClass_100)

- **Data Transfer**: $0.085/GB (primeros 10TB)
- **Requests HTTPS**: $0.01/10K requests

### Ejemplo: 10GB storage, 1M requests/mes, 50GB transfer

```
S3 Storage:    10GB × $0.023 = $0.23
S3 Requests:   1M × $0.0004/1K = $0.40
CloudFront Transfer: 50GB × $0.085 = $4.25
CloudFront Requests: 1M × $0.01/10K = $1.00
Total: ~$5.88/mes
```

## Notas de Rendimiento

- ✅ Latencia típica: 20-100ms (según región)
- ✅ Cache hit rate: ~80-95%
- ✅ Compresión Gzip/Brotli automática
- ✅ HTTP/2 habilitado
- ⚠️ Invalidaciones son lentas (5-10 min)

## Troubleshooting

### Error 403 Forbidden

```
- Verificar que OAI tenga permisos
- Verificar bucket policy
- Verificar que index.html exista
```

### Cambios no se reflejan

```
- Invalidar caché CloudFront
- Verificar cache-control headers
- Limpiar caché del navegador
```

### Error 504 Gateway Timeout

```
- Verificar que el bucket tenga contenido
- Verificar región del bucket
- Verificar OAI configuration
```

## Requisitos

- Terraform >= 1.0
- AWS Provider >= 5.0
- Frontend compilado en `build/` directory

## Mantenimiento

Actualizado: Octubre 2025  
Versión: 1.0.0