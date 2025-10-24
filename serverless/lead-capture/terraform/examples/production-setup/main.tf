# Production Lead Capture Infrastructure Example
# This example demonstrates a production-ready deployment with all security features enabled

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
  
  default_tags {
    tags = {
      Project     = "lead-capture"
      Environment = "production"
      ManagedBy   = "terraform"
      Owner       = "platform-team"
    }
  }
}

# Local values for production configuration
locals {
  project_name = "lead-capture"
  environment  = "prod"
  
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
    Owner       = "platform-team"
    CostCenter  = "marketing"
  }
}

# DynamoDB Table with production settings
module "dynamodb" {
  source = "../../modules/dynamodb"

  table_name   = "${local.project_name}-leads-${local.environment}"
  billing_mode = var.use_provisioned_capacity ? "PROVISIONED" : "PAY_PER_REQUEST"
  
  # Provisioned capacity settings (if enabled)
  read_capacity  = var.use_provisioned_capacity ? var.initial_read_capacity : null
  write_capacity = var.use_provisioned_capacity ? var.initial_write_capacity : null
  
  # GSI capacity
  gsi_read_capacity  = var.use_provisioned_capacity ? var.gsi_read_capacity : null
  gsi_write_capacity = var.use_provisioned_capacity ? var.gsi_write_capacity : null
  
  # Auto scaling for provisioned mode
  enable_autoscaling        = var.use_provisioned_capacity
  read_min_capacity         = var.use_provisioned_capacity ? var.read_min_capacity : null
  read_max_capacity         = var.use_provisioned_capacity ? var.read_max_capacity : null
  write_min_capacity        = var.use_provisioned_capacity ? var.write_min_capacity : null
  write_max_capacity        = var.use_provisioned_capacity ? var.write_max_capacity : null
  read_target_utilization   = 70
  write_target_utilization  = 70
  
  # Security and backup
  enable_encryption             = true
  enable_point_in_time_recovery = true
  enable_backup                 = true
  kms_deletion_window          = 30
  
  # TTL for GDPR compliance
  enable_ttl    = var.enable_data_retention
  ttl_attribute = "expiresAt"
  
  # Streams for real-time processing
  enable_streams   = var.enable_real_time_processing
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  # Monitoring
  enable_monitoring = true
  
  tags = local.common_tags
}

# Lambda Functions with production configuration
module "lambda" {
  source = "../../modules/lambda"

  function_name_prefix = "${local.project_name}-${local.environment}"
  runtime              = "nodejs18.x"
  timeout              = 15  # Shorter timeout for production
  memory_size          = 512 # More memory for better performance

  # Lambda deployment packages
  submit_lambda_zip_path = var.submit_lambda_zip_path
  get_lambda_zip_path    = var.get_lambda_zip_path

  # DynamoDB configuration
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn

  # CORS configuration
  cors_allow_origin = var.cors_allow_origin

  # SES integration
  enable_ses = var.enable_email_notifications

  # Production logging
  log_level          = "WARN"
  log_retention_days = 90
  enable_monitoring  = true

  # Environment variables for production
  submit_lambda_environment_variables = merge(
    var.submit_lambda_environment_variables,
    {
      ENVIRONMENT = local.environment
      RATE_LIMIT_ENABLED = "true"
      SPAM_PROTECTION_ENABLED = "true"
    }
  )
  
  get_lambda_environment_variables = merge(
    var.get_lambda_environment_variables,
    {
      ENVIRONMENT = local.environment
      PAGINATION_ENABLED = "true"
    }
  )

  tags = local.common_tags
}

# API Gateway with production security
module "api_gateway" {
  source = "../../modules/api-gateway"

  api_name        = "${local.project_name}-api-${local.environment}"
  api_description = "Production lead capture API"
  stage_name      = local.environment

  # Lambda function integration
  submit_lambda_invoke_arn    = module.lambda.submit_lambda_invoke_arn
  get_lambda_invoke_arn       = module.lambda.get_lambda_invoke_arn
  submit_lambda_function_name = module.lambda.submit_lambda_function_name
  get_lambda_function_name    = module.lambda.get_lambda_function_name

  # CORS configuration
  cors_allow_origin = var.cors_allow_origin

  # API Key and rate limiting
  enable_api_key         = true
  quota_limit            = var.daily_quota_limit
  quota_period           = "DAY"
  throttle_rate_limit    = var.throttle_rate_limit
  throttle_burst_limit   = var.throttle_burst_limit

  # Custom domain (production)
  custom_domain_name = var.custom_domain_name
  certificate_arn    = var.certificate_arn

  tags = local.common_tags
}

# SES configuration for email notifications
module "ses" {
  count  = var.enable_email_notifications ? 1 : 0
  source = "../../modules/ses"

  # Domain and email configuration
  domain_name      = var.ses_domain_name
  sender_emails    = var.sender_emails
  mail_from_domain = var.mail_from_domain
  
  configuration_set_name = "${local.project_name}-${local.environment}"

  # DKIM and authentication
  enable_dkim               = true
  enable_reputation_metrics = true

  # Bounce and complaint handling
  enable_bounce_handling = true

  # Email templates
  lead_notification_subject = "New Lead: {{name}} from ${var.website_name}"
  enable_welcome_email      = var.enable_welcome_email
  welcome_email_subject     = "Welcome {{name}}! Thanks for contacting ${var.company_name}"

  # Custom templates
  lead_notification_html_template = var.custom_notification_template != "" ? var.custom_notification_template : null
  welcome_email_html_template     = var.custom_welcome_template != "" ? var.custom_welcome_template : null

  # IAM role for Lambda integration
  create_sending_role = true

  # Production monitoring
  enable_monitoring         = true
  enable_cloudwatch_logging = true
  bounce_rate_threshold     = 2.0  # Stricter threshold for production
  complaint_rate_threshold  = 0.1  # Very strict complaint threshold
  log_retention_days        = 90

  tags = local.common_tags
}

# CloudWatch Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "lead_capture" {
  dashboard_name = "${local.project_name}-${local.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", module.lambda.submit_lambda_function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."],
            ["AWS/Lambda", "Invocations", "FunctionName", module.lambda.get_lambda_function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Function Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", module.dynamodb.table_name],
            [".", "ConsumedWriteCapacityUnits", ".", "."],
            [".", "ThrottledRequests", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "DynamoDB Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", module.api_gateway.api_gateway_id],
            [".", "4XXError", ".", "."],
            [".", "5XXError", ".", "."],
            [".", "Latency", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "API Gateway Metrics"
          period  = 300
        }
      }
    ]
  })

  tags = local.common_tags
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${local.project_name}-${local.environment}-alerts"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = length(var.alert_email_addresses)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_addresses[count.index]
}

# CloudWatch Alarms for critical metrics
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${local.project_name}-${local.environment}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors lambda error rate"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = module.lambda.submit_lambda_function_name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttling" {
  alarm_name          = "${local.project_name}-${local.environment}-dynamodb-throttling"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB throttling"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    TableName = module.dynamodb.table_name
  }

  tags = local.common_tags
}