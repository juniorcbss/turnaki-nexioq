# Valores para ambiente QAS

aws_region   = "us-east-1"
project_name = "turnaki-nexioq"
environment  = "qas"

# Cognito
cognito_callback_urls = [
  "https://qas.turnaki.nexioq.com",
  "https://qas.turnaki.nexioq.com/callback"
]

cognito_logout_urls = [
  "https://qas.turnaki.nexioq.com",
  "https://qas.turnaki.nexioq.com/logout"
]

# CORS
cors_allowed_origins = [
  "https://qas.turnaki.nexioq.com"
]

# SES
ses_email_identity  = null
ses_domain_identity = null

# Alarmas
alarm_email = null # Configurar si se desea recibir alarmas en QAS

# Tags
tags = {
  Project    = "Turnaki-NexioQ"
  Team       = "DevOps"
  CostCenter = "QA"
}
