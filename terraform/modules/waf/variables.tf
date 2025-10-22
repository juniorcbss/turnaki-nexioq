# Variables del módulo WAF

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, qas, prd)"
  type        = string
}

variable "scope" {
  description = "Scope del WAF (REGIONAL o CLOUDFRONT)"
  type        = string
  default     = "REGIONAL"
}

variable "rate_limit" {
  description = "Límite de requests por 5 minutos por IP"
  type        = number
  default     = 2000
}

variable "blocked_countries" {
  description = "Lista de códigos de países a bloquear (ej: ['CN', 'RU'])"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

