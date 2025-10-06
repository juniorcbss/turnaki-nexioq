# Outputs del módulo SES

output "email_identity_arn" {
  description = "ARN de la identidad de email"
  value       = var.email_identity != null ? aws_ses_email_identity.sender[0].arn : null
}

output "domain_identity_arn" {
  description = "ARN de la identidad de dominio"
  value       = var.domain_identity != null ? aws_ses_domain_identity.domain[0].arn : null
}

output "dkim_tokens" {
  description = "Tokens DKIM para configurar DNS"
  value       = var.domain_identity != null ? aws_ses_domain_dkim.domain[0].dkim_tokens : []
}

output "configuration_set_name" {
  description = "Nombre del configuration set"
  value       = aws_ses_configuration_set.main.name
}

