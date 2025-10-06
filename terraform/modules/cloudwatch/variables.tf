# Variables del módulo CloudWatch

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, qas, prd)"
  type        = string
}

variable "region" {
  description = "Región de AWS"
  type        = string
}

variable "enable_alarms" {
  description = "Habilitar alarmas"
  type        = bool
  default     = false
}

variable "alarm_email" {
  description = "Email para notificaciones de alarmas"
  type        = string
  default     = null
}

variable "lambda_error_threshold" {
  description = "Umbral de errores Lambda"
  type        = number
  default     = 10
}

variable "api_5xx_threshold" {
  description = "Umbral de errores 5XX API Gateway"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

