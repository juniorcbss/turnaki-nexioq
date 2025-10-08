# Configuración ambiente PRD
# Orquestador de módulos para PRODUCCIÓN
# Configuraciones optimizadas para alta disponibilidad y rendimiento

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
      Criticality = "High"
    }
  }
}

# DynamoDB con configuraciones de producción
module "dynamodb" {
  source = "../../modules/dynamodb"

  project_name                  = var.project_name
  environment                   = var.environment
  billing_mode                  = "PAY_PER_REQUEST"
  enable_point_in_time_recovery = true # ✅ OBLIGATORIO en PRD

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

# API Gateway con configuración de producción
module "api_gateway" {
  source = "../../modules/api-gateway"

  project_name         = var.project_name
  environment          = var.environment
  cors_allowed_origins = var.cors_allowed_origins
  cognito_client_id    = module.cognito.client_id
  cognito_issuer       = module.cognito.issuer
  throttle_burst_limit = 500 # Alta capacidad para PRD
  throttle_rate_limit  = 250
  log_retention_days   = 30 # Retención extendida

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

# Lambda Functions con configuraciones optimizadas para PRD
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
  log_level           = "warn" # Solo warnings/errors en PRD
  log_retention_days  = 30
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
  memory_size         = 1024 # Mayor memoria en PRD
  log_level           = "warn"
  log_retention_days  = 30
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
  memory_size         = 1024
  log_level           = "warn"
  log_retention_days  = 30
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
  memory_size         = 1024
  log_level           = "warn"
  log_retention_days  = 30
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
  memory_size         = 1024
  log_level           = "warn"
  log_retention_days  = 30
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
  memory_size         = 1024
  log_level           = "warn"
  log_retention_days  = 30
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
  memory_size         = 1024
  log_level           = "warn"
  log_retention_days  = 30
  api_gateway_arn     = module.api_gateway.api_execution_arn

  environment_variables = {
    SES_CONFIGURATION_SET   = module.ses.configuration_set_name
    SCHEDULER_ROLE_ARN      = aws_iam_role.eventbridge_scheduler.arn
    NOTIFICATION_LAMBDA_ARN = module.lambda_send_notification.function_arn
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
  memory_size         = 1024
  log_level           = "warn"
  log_retention_days  = 30

  environment_variables = {
    SES_CONFIGURATION_SET = module.ses.configuration_set_name
  }

  tags = var.tags
}

# Frontend con configuración de producción
module "frontend" {
  source = "../../modules/s3-cloudfront"

  project_name      = var.project_name
  environment       = var.environment
  enable_versioning = true             # ✅ Versionado obligatorio en PRD
  price_class       = "PriceClass_All" # ✅ Distribución global en PRD

  tags = var.tags
}

# WAF con protección reforzada
module "waf" {
  source = "../../modules/waf"

  project_name = var.project_name
  environment  = var.environment
  scope        = "REGIONAL"
  rate_limit   = 2000 # Límite de producción

  tags = var.tags
}

# CloudWatch con alarmas críticas habilitadas
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  project_name           = var.project_name
  environment            = var.environment
  region                 = var.aws_region
  enable_alarms          = true # ✅ OBLIGATORIO en PRD
  alarm_email            = var.alarm_email
  lambda_error_threshold = 5 # Baja tolerancia en PRD
  api_5xx_threshold      = 5

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