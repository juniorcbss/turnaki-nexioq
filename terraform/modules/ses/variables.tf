# Variables del módulo SES

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, qas, prd)"
  type        = string
}

variable "email_identity" {
  description = "Email para verificar en SES (opcional)"
  type        = string
  default     = null
}

variable "domain_identity" {
  description = "Dominio para verificar en SES (opcional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

