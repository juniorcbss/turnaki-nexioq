# Outputs del módulo IAM

output "role_arn" {
  description = "ARN del rol IAM"
  value       = aws_iam_role.lambda_role.arn
}

output "role_name" {
  description = "Nombre del rol IAM"
  value       = aws_iam_role.lambda_role.name
}

