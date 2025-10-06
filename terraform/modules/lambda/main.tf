# Módulo Lambda - Función genérica
# Propósito: Lambda function reutilizable para Rust

resource "aws_lambda_function" "function" {
  function_name = "${var.project_name}-${var.environment}-${var.function_name}"
  role          = var.iam_role_arn
  handler       = "bootstrap"
  runtime       = "provided.al2023"
  architectures = ["arm64"]

  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  timeout     = var.timeout
  memory_size = var.memory_size

  environment {
    variables = merge(
      {
        RUST_LOG   = var.log_level
        LOG_LEVEL  = var.log_level
        TABLE_NAME = var.dynamodb_table_name
      },
      var.environment_variables
    )
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-${var.function_name}"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_log_group" "function" {
  name              = "/aws/lambda/${aws_lambda_function.function.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_lambda_permission" "api_gateway" {
  for_each = var.api_gateway_arn != null ? toset(["api_gateway"]) : toset([])

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_arn}/*/*"
}

