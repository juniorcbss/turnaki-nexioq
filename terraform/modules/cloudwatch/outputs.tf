# Outputs del módulo CloudWatch

output "dashboard_name" {
  description = "Nombre del dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "sns_topic_arn" {
  description = "ARN del SNS topic de alarmas"
  value       = aws_sns_topic.alarms.arn
}

