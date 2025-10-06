# Variables del módulo Lambda

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

variable "iam_role_arn" {
  description = "ARN del rol IAM para la función"
  type        = string
}

variable "lambda_zip_path" {
  description = "Ruta al archivo ZIP con el código Lambda"
  type        = string
}

variable "timeout" {
  description = "Timeout de la función en segundos"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Memoria asignada en MB"
  type        = number
  default     = 512
}

variable "log_level" {
  description = "Nivel de log (info, debug, error)"
  type        = string
  default     = "info"
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB"
  type        = string
}

variable "environment_variables" {
  description = "Variables de entorno adicionales"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Días de retención de logs"
  type        = number
  default     = 7
}

variable "api_gateway_arn" {
  description = "ARN del API Gateway (opcional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

