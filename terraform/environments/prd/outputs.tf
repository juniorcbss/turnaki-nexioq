# Outputs del ambiente PRD

# DynamoDB
output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "ARN de la tabla DynamoDB"
  value       = module.dynamodb.table_arn
}

# Cognito
output "cognito_user_pool_id" {
  description = "ID del User Pool"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "ID del Client"
  value       = module.cognito.client_id
  sensitive   = true # Sensible en PRD
}

output "cognito_domain" {
  description = "Dominio de Cognito"
  value       = module.cognito.domain
}

output "cognito_issuer" {
  description = "Issuer URL de Cognito"
  value       = module.cognito.issuer
}

# API Gateway
output "api_endpoint" {
  description = "Endpoint del API Gateway"
  value       = module.api_gateway.api_endpoint
}

output "api_id" {
  description = "ID del API Gateway"
  value       = module.api_gateway.api_id
}

# Lambda Functions
output "lambda_health_arn" {
  description = "ARN de Lambda Health"
  value       = module.lambda_health.function_arn
}

output "lambda_bookings_arn" {
  description = "ARN de Lambda Bookings"
  value       = module.lambda_bookings.function_arn
}

output "lambda_availability_arn" {
  description = "ARN de Lambda Availability"
  value       = module.lambda_availability.function_arn
}

output "lambda_professionals_arn" {
  description = "ARN de Lambda Professionals"
  value       = module.lambda_professionals.function_arn
}

output "lambda_tenants_arn" {
  description = "ARN de Lambda Tenants"
  value       = module.lambda_tenants.function_arn
}

output "lambda_treatments_arn" {
  description = "ARN de Lambda Treatments"
  value       = module.lambda_treatments.function_arn
}

output "lambda_send_notification_arn" {
  description = "ARN de Lambda Send Notification"
  value       = module.lambda_send_notification.function_arn
}

output "lambda_schedule_reminder_arn" {
  description = "ARN de Lambda Schedule Reminder"
  value       = module.lambda_schedule_reminder.function_arn
}

# Frontend
output "frontend_bucket_name" {
  description = "Nombre del bucket S3 frontend"
  value       = module.frontend.bucket_name
}

output "cloudfront_url" {
  description = "URL de CloudFront"
  value       = module.frontend.cloudfront_url
}

output "cloudfront_distribution_id" {
  description = "ID de distribución CloudFront"
  value       = module.frontend.cloudfront_distribution_id
}

# WAF
output "waf_web_acl_arn" {
  description = "ARN del WAF Web ACL"
  value       = module.waf.web_acl_arn
}

output "waf_web_acl_id" {
  description = "ID del WAF Web ACL"
  value       = module.waf.web_acl_id
}

# CloudWatch
output "cloudwatch_dashboard_name" {
  description = "Nombre del dashboard CloudWatch"
  value       = module.cloudwatch.dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "URL del dashboard CloudWatch"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.cloudwatch.dashboard_name}"
}

output "cloudwatch_sns_topic_arn" {
  description = "ARN del SNS topic para alarmas críticas"
  value       = module.cloudwatch.sns_topic_arn
}

# SES
output "ses_configuration_set" {
  description = "Nombre del configuration set SES"
  value       = module.ses.configuration_set_name
}

# Resumen de URLs importantes para PRD
output "production_summary" {
  description = "Resumen de URLs y endpoints de producción"
  value = {
    api_endpoint   = module.api_gateway.api_endpoint
    frontend_url   = module.frontend.cloudfront_url
    cognito_domain = module.cognito.domain
    dashboard_url  = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.cloudwatch.dashboard_name}"
  }
}
