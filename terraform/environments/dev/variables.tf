# Variables del ambiente DEV

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "dev"
}

variable "cognito_callback_urls" {
  description = "URLs de callback para Cognito"
  type        = list(string)
}

variable "cognito_logout_urls" {
  description = "URLs de logout para Cognito"
  type        = list(string)
}

variable "cors_allowed_origins" {
  description = "Orígenes permitidos para CORS"
  type        = list(string)
}

variable "ses_email_identity" {
  description = "Email para SES (opcional)"
  type        = string
  default     = null
}

variable "ses_domain_identity" {
  description = "Dominio para SES (opcional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}
