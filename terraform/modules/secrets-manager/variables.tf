# Variables del módulo Secrets Manager

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, qas, prd)"
  type        = string
}

variable "secrets" {
  description = "Mapa de secretos a crear. Formato: { secret_name = { description = \"...\", value = {...} } }"
  type = map(object({
    description = string
    value       = any
  }))
  default = {}
}

variable "recovery_window_in_days" {
  description = "Ventana de recuperación en días para secretos eliminados"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

