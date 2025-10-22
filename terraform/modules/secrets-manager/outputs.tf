# Outputs del módulo Secrets Manager

output "secret_arns" {
  description = "ARNs de los secretos creados"
  value = {
    for k, v in aws_secretsmanager_secret.main : k => v.arn
  }
}

output "secret_names" {
  description = "Nombres de los secretos creados"
  value = {
    for k, v in aws_secretsmanager_secret.main : k => v.name
  }
}

output "secrets_access_policy_arn" {
  description = "ARN de la política de acceso a secrets"
  value       = length(aws_iam_policy.secrets_access) > 0 ? aws_iam_policy.secrets_access[0].arn : null
}

