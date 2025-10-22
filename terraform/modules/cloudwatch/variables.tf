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

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para alarmas"
  type        = string
  default     = null
}

variable "dynamodb_capacity_threshold" {
  description = "Umbral de capacidad consumida en DynamoDB"
  type        = number
  default     = 10000
}

variable "waf_web_acl_name" {
  description = "Nombre del Web ACL de WAF para alarmas"
  type        = string
  default     = null
}

variable "waf_blocked_threshold" {
  description = "Umbral de requests bloqueados por WAF"
  type        = number
  default     = 100
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

