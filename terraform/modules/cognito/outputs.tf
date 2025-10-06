# Outputs del módulo Cognito

output "user_pool_id" {
  description = "ID del User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "ARN del User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Endpoint del User Pool"
  value       = aws_cognito_user_pool.main.endpoint
}

output "client_id" {
  description = "ID del User Pool Client"
  value       = aws_cognito_user_pool_client.main.id
}

output "domain" {
  description = "Dominio de Cognito"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "issuer" {
  description = "Issuer URL para JWT"
  value       = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.main.id}"
}

data "aws_region" "current" {}

