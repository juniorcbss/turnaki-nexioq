# Variables del módulo S3-CloudFront

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, qas, prd)"
  type        = string
}

variable "enable_versioning" {
  description = "Habilitar versionado de S3"
  type        = bool
  default     = false
}

variable "price_class" {
  description = "Clase de precio de CloudFront"
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

