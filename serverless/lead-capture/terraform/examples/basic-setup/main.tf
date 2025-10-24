# Basic Lead Capture Infrastructure Example
# This example demonstrates how to use all the lead capture Terraform modules together

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Local values for common configuration
locals {
  project_name = "lead-capture-example"
  environment  = "dev"
  
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

# DynamoDB Table for storing leads
module "dynamodb" {
  source = "../../modules/dynamodb"

  table_name                    = "${local.project_name}-leads-${local.environment}"
  billing_mode                  = "PAY_PER_REQUEST"
  enable_encryption             = true
  enable_point_in_time_recovery = true
  enable_monitoring             = true
  
  tags = local.common_tags
}

# Lambda Functions for API handlers
module "lambda" {
  source = "../../modules/lambda"

  function_name_prefix = "${local.project_name}-${local.environment}"
  runtime              = "nodejs18.x"
  timeout              = 30
  memory_size          = 256

  # Lambda deployment packages (you need to create these ZIP files)
  submit_lambda_zip_path = var.submit_lambda_zip_path
  get_lambda_zip_path    = var.get_lambda_zip_path

  # DynamoDB configuration
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn

  # CORS configuration
  cors_allow_origin = var.cors_allow_origin

  # Optional SES integration
  enable_ses = var.enable_email_notifications

  # Monitoring
  enable_monitoring    = true
  log_retention_days   = 14

  tags = local.common_tags
}

# API Gateway for REST API
module "api_gateway" {
  source = "../../modules/api-gateway"

  api_name        = "${local.project_name}-api-${local.environment}"
  api_description = "Lead capture API for ${local.project_name}"
  stage_name      = local.environment

  # Lambda function integration
  submit_lambda_invoke_arn    = module.lambda.submit_lambda_invoke_arn
  get_lambda_invoke_arn       = module.lambda.get_lambda_invoke_arn
  submit_lambda_function_name = module.lambda.submit_lambda_function_name
  get_lambda_function_name    = module.lambda.get_lambda_function_name

  # CORS configuration
  cors_allow_origin = var.cors_allow_origin

  # API Key configuration
  enable_api_key         = var.enable_api_key
  quota_limit            = 10000
  quota_period           = "DAY"
  throttle_rate_limit    = 100
  throttle_burst_limit   = 200

  # Optional custom domain
  custom_domain_name = var.custom_domain_name
  certificate_arn    = var.certificate_arn

  tags = local.common_tags
}

# Optional SES configuration for email notifications
module "ses" {
  count  = var.enable_email_notifications ? 1 : 0
  source = "../../modules/ses"

  # Email configuration
  sender_emails           = var.sender_emails
  domain_name            = var.ses_domain_name
  configuration_set_name = "${local.project_name}-${local.environment}"

  # DKIM and domain settings
  enable_dkim        = true
  mail_from_domain   = var.mail_from_domain

  # Monitoring and logging
  enable_monitoring         = true
  enable_cloudwatch_logging = true
  enable_bounce_handling    = true
  log_retention_days        = 14

  # Email templates
  lead_notification_subject = "New Lead: {{name}} from ${local.project_name}"
  enable_welcome_email      = var.enable_welcome_email

  # IAM role for Lambda integration
  create_sending_role = true

  tags = local.common_tags
}