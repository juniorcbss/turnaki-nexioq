# Variables del módulo API Gateway

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, qas, prd)"
  type        = string
}

variable "cors_allowed_origins" {
  description = "Orígenes permitidos para CORS"
  type        = list(string)
}

variable "cognito_client_id" {
  description = "ID del Cognito Client"
  type        = string
}

variable "cognito_issuer" {
  description = "Issuer URL de Cognito"
  type        = string
}

variable "throttle_burst_limit" {
  description = "Límite de ráfaga para throttling"
  type        = number
  default     = 100
}

variable "throttle_rate_limit" {
  description = "Límite de tasa para throttling"
  type        = number
  default     = 50
}

variable "log_retention_days" {
  description = "Días de retención de logs"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

