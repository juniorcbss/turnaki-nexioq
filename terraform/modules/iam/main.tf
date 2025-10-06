# Módulo IAM - Roles y políticas para Lambda
# Propósito: Gestionar roles IAM reutilizables para funciones Lambda

resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-${var.environment}-lambda-${var.function_name}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-lambda-${var.function_name}"
    Environment = var.environment
  })
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Política personalizada para DynamoDB
resource "aws_iam_role_policy" "dynamodb_access" {
  for_each = var.dynamodb_table_arn != null ? toset(["dynamodb"]) : toset([])
  role     = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      }
    ]
  })
}

# Política personalizada para SES
resource "aws_iam_role_policy" "ses_access" {
  for_each = var.enable_ses_access ? toset(["ses"]) : toset([])
  role     = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

