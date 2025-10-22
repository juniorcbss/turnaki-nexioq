# Módulo Secrets Manager - Gestión de secretos sensibles
# Propósito: Almacenar configuraciones sensibles de forma segura

resource "aws_secretsmanager_secret" "main" {
  for_each = var.secrets

  name        = "${var.project_name}-${var.environment}-${each.key}"
  description = each.value.description

  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-${each.key}"
    Environment = var.environment
  })
}

resource "aws_secretsmanager_secret_version" "main" {
  for_each = var.secrets

  secret_id     = aws_secretsmanager_secret.main[each.key].id
  secret_string = jsonencode(each.value.value)

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# IAM Policy para permitir que las Lambdas lean los secretos
resource "aws_iam_policy" "secrets_access" {
  count = length(var.secrets) > 0 ? 1 : 0

  name        = "${var.project_name}-${var.environment}-secrets-access"
  description = "Permite acceso a Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          for secret in aws_secretsmanager_secret.main : secret.arn
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-secrets-access"
    Environment = var.environment
  })
}

