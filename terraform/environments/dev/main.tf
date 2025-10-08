# Configuración ambiente DEV
# Orquestador de módulos para desarrollo

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# DynamoDB
module "dynamodb" {
  source = "../../modules/dynamodb"

  project_name                  = var.project_name
  environment                   = var.environment
  billing_mode                  = "PAY_PER_REQUEST"
  enable_point_in_time_recovery = false

  tags = var.tags
}

# Cognito
module "cognito" {
  source = "../../modules/cognito"

  project_name = var.project_name
  environment  = var.environment

  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_logout_urls

  tags = var.tags
}

# API Gateway
module "api_gateway" {
  source = "../../modules/api-gateway"

  project_name         = var.project_name
  environment          = var.environment
  cors_allowed_origins = var.cors_allowed_origins
  cognito_client_id    = module.cognito.client_id
  cognito_issuer       = module.cognito.issuer
  throttle_burst_limit = 100
  throttle_rate_limit  = 50
  log_retention_days   = 7

  tags = var.tags
}

# IAM Roles para cada Lambda
module "iam_health" {
  source = "../../modules/iam"

  project_name       = var.project_name
  environment        = var.environment
  function_name      = "health"
  dynamodb_table_arn = null
  enable_ses_access  = false

  tags = var.tags
}

module "iam_bookings" {
  source = "../../modules/iam"

  project_name       = var.project_name
  environment        = var.environment
  function_name      = "bookings"
  dynamodb_table_arn = module.dynamodb.table_arn
  enable_ses_access  = false

  tags = var.tags
}

module "iam_availability" {
  source = "../../modules/iam"

  project_name       = var.project_name
  environment        = var.environment
  function_name      = "availability"
  dynamodb_table_arn = module.dynamodb.table_arn
  enable_ses_access  = false

  tags = var.tags
}

module "iam_professionals" {
  source = "../../modules/iam"

  project_name       = var.project_name
  environment        = var.environment
  function_name      = "professionals"
  dynamodb_table_arn = module.dynamodb.table_arn
  enable_ses_access  = false

  tags = var.tags
}

module "iam_tenants" {
  source = "../../modules/iam"

  project_name       = var.project_name
  environment        = var.environment
  function_name      = "tenants"
  dynamodb_table_arn = module.dynamodb.table_arn
  enable_ses_access  = false

  tags = var.tags
}

module "iam_treatments" {
  source = "../../modules/iam"

  project_name       = var.project_name
  environment        = var.environment
  function_name      = "treatments"
  dynamodb_table_arn = module.dynamodb.table_arn
  enable_ses_access  = false

  tags = var.tags
}

module "iam_send_notification" {
  source = "../../modules/iam"

  project_name       = var.project_name
  environment        = var.environment
  function_name      = "send-notification"
  dynamodb_table_arn = module.dynamodb.table_arn
  enable_ses_access  = true

  tags = var.tags
}

module "iam_schedule_reminder" {
  source = "../../modules/iam"

  project_name       = var.project_name
  environment        = var.environment
  function_name      = "schedule-reminder"
  dynamodb_table_arn = module.dynamodb.table_arn
  enable_ses_access  = true

  tags = var.tags
}

# Lambda Functions
module "lambda_health" {
  source = "../../modules/lambda"

  project_name        = var.project_name
  environment         = var.environment
  function_name       = "health"
  iam_role_arn        = module.iam_health.role_arn
  lambda_zip_path     = "${path.module}/../../../backend/target/lambda/health/bootstrap.zip"
  dynamodb_table_name = module.dynamodb.table_name
  timeout             = 10
  memory_size         = 256
  log_level           = "info"
  log_retention_days  = 7
  api_gateway_arn     = module.api_gateway.api_execution_arn

  tags = var.tags
}

module "lambda_bookings" {
  source = "../../modules/lambda"

  project_name        = var.project_name
  environment         = var.environment
  function_name       = "bookings"
  iam_role_arn        = module.iam_bookings.role_arn
  lambda_zip_path     = "${path.module}/../../../backend/target/lambda/bookings/bootstrap.zip"
  dynamodb_table_name = module.dynamodb.table_name
  timeout             = 30
  memory_size         = 512
  log_level           = "info"
  log_retention_days  = 7
  api_gateway_arn     = module.api_gateway.api_execution_arn

  environment_variables = {
    COGNITO_USER_POOL_ID = module.cognito.user_pool_id
  }

  tags = var.tags
}

module "lambda_availability" {
  source = "../../modules/lambda"

  project_name        = var.project_name
  environment         = var.environment
  function_name       = "availability"
  iam_role_arn        = module.iam_availability.role_arn
  lambda_zip_path     = "${path.module}/../../../backend/target/lambda/availability/bootstrap.zip"
  dynamodb_table_name = module.dynamodb.table_name
  timeout             = 30
  memory_size         = 512
  log_level           = "info"
  log_retention_days  = 7
  api_gateway_arn     = module.api_gateway.api_execution_arn

  tags = var.tags
}

module "lambda_professionals" {
  source = "../../modules/lambda"

  project_name        = var.project_name
  environment         = var.environment
  function_name       = "professionals"
  iam_role_arn        = module.iam_professionals.role_arn
  lambda_zip_path     = "${path.module}/../../../backend/target/lambda/professionals/bootstrap.zip"
  dynamodb_table_name = module.dynamodb.table_name
  timeout             = 30
  memory_size         = 512
  log_level           = "info"
  log_retention_days  = 7
  api_gateway_arn     = module.api_gateway.api_execution_arn

  tags = var.tags
}

module "lambda_tenants" {
  source = "../../modules/lambda"

  project_name        = var.project_name
  environment         = var.environment
  function_name       = "tenants"
  iam_role_arn        = module.iam_tenants.role_arn
  lambda_zip_path     = "${path.module}/../../../backend/target/lambda/tenants/bootstrap.zip"
  dynamodb_table_name = module.dynamodb.table_name
  timeout             = 30
  memory_size         = 512
  log_level           = "info"
  log_retention_days  = 7
  api_gateway_arn     = module.api_gateway.api_execution_arn

  tags = var.tags
}

module "lambda_treatments" {
  source = "../../modules/lambda"

  project_name        = var.project_name
  environment         = var.environment
  function_name       = "treatments"
  iam_role_arn        = module.iam_treatments.role_arn
  lambda_zip_path     = "${path.module}/../../../backend/target/lambda/treatments/bootstrap.zip"
  dynamodb_table_name = module.dynamodb.table_name
  timeout             = 30
  memory_size         = 512
  log_level           = "info"
  log_retention_days  = 7
  api_gateway_arn     = module.api_gateway.api_execution_arn

  tags = var.tags
}

module "lambda_send_notification" {
  source = "../../modules/lambda"

  project_name        = var.project_name
  environment         = var.environment
  function_name       = "send-notification"
  iam_role_arn        = module.iam_send_notification.role_arn
  lambda_zip_path     = "${path.module}/../../../backend/target/lambda/send-notification/bootstrap.zip"
  dynamodb_table_name = module.dynamodb.table_name
  timeout             = 30
  memory_size         = 512
  log_level           = "info"
  log_retention_days  = 7
  api_gateway_arn     = module.api_gateway.api_execution_arn

  environment_variables = {
    SES_CONFIGURATION_SET = module.ses.configuration_set_name
  }

  tags = var.tags
}

resource "aws_iam_role" "eventbridge_scheduler" {
  name               = "${var.project_name}-${var.environment}-eventbridge-scheduler"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "scheduler.amazonaws.com" }
        Action   = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "eventbridge_scheduler_invoke" {
  role = aws_iam_role.eventbridge_scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [module.lambda_send_notification.function_arn]
      }
    ]
  })
}

module "lambda_schedule_reminder" {
  source = "../../modules/lambda"

  project_name        = var.project_name
  environment         = var.environment
  function_name       = "schedule-reminder"
  iam_role_arn        = module.iam_schedule_reminder.role_arn
  lambda_zip_path     = "${path.module}/../../../backend/target/lambda/schedule-reminder/bootstrap.zip"
  dynamodb_table_name = module.dynamodb.table_name
  timeout             = 30
  memory_size         = 512
  log_level           = "info"
  log_retention_days  = 7

  environment_variables = {
    SES_CONFIGURATION_SET   = module.ses.configuration_set_name
    SCHEDULER_ROLE_ARN      = aws_iam_role.eventbridge_scheduler.arn
    NOTIFICATION_LAMBDA_ARN = module.lambda_send_notification.function_arn
  }

  tags = var.tags
}

# Frontend (S3 + CloudFront)
module "frontend" {
  source = "../../modules/s3-cloudfront"

  project_name      = var.project_name
  environment       = var.environment
  enable_versioning = false
  price_class       = "PriceClass_100"

  tags = var.tags
}

# WAF
module "waf" {
  source = "../../modules/waf"

  project_name = var.project_name
  environment  = var.environment
  scope        = "REGIONAL"
  rate_limit   = 2000

  tags = var.tags
}

# CloudWatch
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  project_name           = var.project_name
  environment            = var.environment
  region                 = var.aws_region
  enable_alarms          = false
  alarm_email            = null
  lambda_error_threshold = 10
  api_5xx_threshold      = 10

  tags = var.tags
}

# SES
module "ses" {
  source = "../../modules/ses"

  project_name    = var.project_name
  environment     = var.environment
  email_identity  = var.ses_email_identity
  domain_identity = var.ses_domain_identity

  tags = var.tags
}
