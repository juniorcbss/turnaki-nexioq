# Valores para ambiente DEV

aws_region   = "us-east-1"
project_name = "turnaki-nexioq"
environment  = "dev"

# Cognito
cognito_callback_urls = [
  "http://localhost:5173",
  "http://localhost:5173/callback",
  "https://d2rwm4uq5d71nu.cloudfront.net/auth/callback"
]

cognito_logout_urls = [
  "http://localhost:5173",
  "http://localhost:5173/logout",
  "https://d2rwm4uq5d71nu.cloudfront.net"
]

# CORS
cors_allowed_origins = [
  "http://localhost:5173",
  "http://127.0.0.1:5173",
  "https://d2rwm4uq5d71nu.cloudfront.net"
]

# SES
ses_email_identity  = null # Cambiar por email verificado si es necesario
ses_domain_identity = null

# Tags
tags = {
  Project    = "Turnaki-NexioQ"
  Team       = "DevOps"
  CostCenter = "Development"
}
