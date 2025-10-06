# Outputs del ambiente DEV

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
}

output "cognito_domain" {
  description = "Dominio de Cognito"
  value       = module.cognito.domain
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

# CloudWatch
output "cloudwatch_dashboard_name" {
  description = "Nombre del dashboard CloudWatch"
  value       = module.cloudwatch.dashboard_name
}

# SES
output "ses_configuration_set" {
  description = "Nombre del configuration set SES"
  value       = module.ses.configuration_set_name
}
