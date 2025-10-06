# Outputs del módulo API Gateway

output "api_id" {
  description = "ID del API Gateway"
  value       = aws_apigatewayv2_api.main.id
}

output "api_endpoint" {
  description = "Endpoint del API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "api_execution_arn" {
  description = "ARN de ejecución del API Gateway"
  value       = aws_apigatewayv2_api.main.execution_arn
}

output "authorizer_id" {
  description = "ID del JWT Authorizer"
  value       = aws_apigatewayv2_authorizer.jwt.id
}

output "stage_id" {
  description = "ID del Stage"
  value       = aws_apigatewayv2_stage.default.id
}

