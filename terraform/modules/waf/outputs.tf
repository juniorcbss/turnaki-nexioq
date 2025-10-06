# Outputs del módulo WAF

output "web_acl_id" {
  description = "ID del Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "web_acl_arn" {
  description = "ARN del Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "web_acl_capacity" {
  description = "Capacidad del Web ACL"
  value       = aws_wafv2_web_acl.main.capacity
}

