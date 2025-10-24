# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.function_name_prefix}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_role.name
}

# Custom IAM policy for DynamoDB access
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "${var.function_name_prefix}-dynamodb-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      }
    ]
  })
}

# Custom IAM policy for SES (if enabled)
resource "aws_iam_role_policy" "lambda_ses_policy" {
  count = var.enable_ses ? 1 : 0
  name  = "${var.function_name_prefix}-ses-policy"
  role  = aws_iam_role.lambda_execution_role.id

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

# CloudWatch Log Group for Submit Lambda
resource "aws_cloudwatch_log_group" "submit_lambda_logs" {
  name              = "/aws/lambda/${var.function_name_prefix}-submit-lead"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# CloudWatch Log Group for Get Lambda
resource "aws_cloudwatch_log_group" "get_lambda_logs" {
  name              = "/aws/lambda/${var.function_name_prefix}-get-leads"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Submit Lead Lambda Function
resource "aws_lambda_function" "submit_lead" {
  filename         = var.submit_lambda_zip_path
  function_name    = "${var.function_name_prefix}-submit-lead"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = var.submit_lambda_handler
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size

  source_code_hash = filebase64sha256(var.submit_lambda_zip_path)

  environment {
    variables = merge(
      {
        DYNAMODB_TABLE_NAME = var.dynamodb_table_name
        CORS_ALLOW_ORIGIN   = var.cors_allow_origin
        LOG_LEVEL          = var.log_level
      },
      var.submit_lambda_environment_variables
    )
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.submit_lambda_logs,
  ]

  tags = var.tags
}

# Get Leads Lambda Function
resource "aws_lambda_function" "get_leads" {
  filename         = var.get_lambda_zip_path
  function_name    = "${var.function_name_prefix}-get-leads"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = var.get_lambda_handler
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size

  source_code_hash = filebase64sha256(var.get_lambda_zip_path)

  environment {
    variables = merge(
      {
        DYNAMODB_TABLE_NAME = var.dynamodb_table_name
        LOG_LEVEL          = var.log_level
      },
      var.get_lambda_environment_variables
    )
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.get_lambda_logs,
  ]

  tags = var.tags
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "submit_lambda_errors" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.function_name_prefix}-submit-lead-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors lambda errors for submit-lead function"

  dimensions = {
    FunctionName = aws_lambda_function.submit_lead.function_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "submit_lambda_duration" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.function_name_prefix}-submit-lead-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "10000"  # 10 seconds
  alarm_description   = "This metric monitors lambda duration for submit-lead function"

  dimensions = {
    FunctionName = aws_lambda_function.submit_lead.function_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "get_lambda_errors" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.function_name_prefix}-get-leads-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors lambda errors for get-leads function"

  dimensions = {
    FunctionName = aws_lambda_function.get_leads.function_name
  }

  tags = var.tags
}