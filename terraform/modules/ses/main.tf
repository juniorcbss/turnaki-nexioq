# Módulo SES - Simple Email Service
# Propósito: Envío de emails transaccionales

resource "aws_ses_email_identity" "sender" {
  count = var.email_identity != null ? 1 : 0
  email = var.email_identity
}

resource "aws_ses_domain_identity" "domain" {
  count  = var.domain_identity != null ? 1 : 0
  domain = var.domain_identity
}

resource "aws_ses_domain_dkim" "domain" {
  count  = var.domain_identity != null ? 1 : 0
  domain = aws_ses_domain_identity.domain[0].domain
}

# Configuration Set para tracking
resource "aws_ses_configuration_set" "main" {
  name = "${var.project_name}-${var.environment}-emails"
}

resource "aws_ses_event_destination" "cloudwatch" {
  name                   = "cloudwatch-destination"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types         = ["send", "reject", "bounce", "complaint", "delivery"]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "EmailType"
    value_source   = "messageTag"
  }
}

