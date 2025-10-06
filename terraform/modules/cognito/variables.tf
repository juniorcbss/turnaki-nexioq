# Variables del módulo Cognito

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, qas, prd)"
  type        = string
}

variable "callback_urls" {
  description = "URLs de callback para OAuth"
  type        = list(string)
}

variable "logout_urls" {
  description = "URLs de logout para OAuth"
  type        = list(string)
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

