# Valores para ambiente PRD

aws_region   = "us-east-1"
project_name = "turnaki-nexioq"
environment  = "prd"

# Cognito
cognito_callback_urls = [
  "https://turnaki.nexioq.com",
  "https://turnaki.nexioq.com/callback"
]

cognito_logout_urls = [
  "https://turnaki.nexioq.com",
  "https://turnaki.nexioq.com/logout"
]

# CORS
cors_allowed_origins = [
  "https://turnaki.nexioq.com"
]

# SES
ses_email_identity  = null # Configurar email verificado
ses_domain_identity = null

# Alarmas
alarm_email = "alerts@turnaki.com" # Cambiar por email real

# Tags
tags = {
  Project     = "Turnaki-NexioQ"
  Team        = "DevOps"
  CostCenter  = "Production"
  Criticality = "High"
}
