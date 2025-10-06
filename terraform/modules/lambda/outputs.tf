# Outputs del módulo Lambda

output "function_arn" {
  description = "ARN de la función Lambda"
  value       = aws_lambda_function.function.arn
}

output "function_name" {
  description = "Nombre de la función Lambda"
  value       = aws_lambda_function.function.function_name
}

output "function_invoke_arn" {
  description = "ARN de invocación de la función"
  value       = aws_lambda_function.function.invoke_arn
}

output "log_group_name" {
  description = "Nombre del CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.function.name
}

