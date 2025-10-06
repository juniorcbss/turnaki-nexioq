# Variables del módulo IAM

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, qas, prd)"
  type        = string
}

variable "function_name" {
  description = "Nombre de la función Lambda"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN de la tabla DynamoDB (opcional)"
  type        = string
  default     = null
}

variable "enable_ses_access" {
  description = "Habilitar acceso a SES"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

