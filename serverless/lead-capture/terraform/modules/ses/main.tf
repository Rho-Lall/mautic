# SES Domain Identity
resource "aws_ses_domain_identity" "main" {
  count  = var.domain_name != "" ? 1 : 0
  domain = var.domain_name
}

# SES Domain DKIM
resource "aws_ses_domain_dkim" "main" {
  count  = var.domain_name != "" && var.enable_dkim ? 1 : 0
  domain = aws_ses_domain_identity.main[0].domain
}

# SES Email Identity (for individual email addresses)
resource "aws_ses_email_identity" "sender_emails" {
  for_each = toset(var.sender_emails)
  email    = each.value
}

# SES Domain Mail From
resource "aws_ses_domain_mail_from" "main" {
  count            = var.domain_name != "" && var.mail_from_domain != "" ? 1 : 0
  domain           = aws_ses_domain_identity.main[0].domain
  mail_from_domain = var.mail_from_domain
}

# SES Configuration Set
resource "aws_ses_configuration_set" "main" {
  name = var.configuration_set_name

  delivery_options {
    tls_policy = "Require"
  }

  reputation_metrics_enabled = var.enable_reputation_metrics
}

# SES Event Destination for Bounce Handling
resource "aws_ses_event_destination" "bounce" {
  count                  = var.enable_bounce_handling ? 1 : 0
  name                   = "${var.configuration_set_name}-bounce"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types         = ["bounce", "complaint"]

  sns_destination {
    topic_arn = aws_sns_topic.ses_notifications[0].arn
  }
}

# SNS Topic for SES notifications
resource "aws_sns_topic" "ses_notifications" {
  count = var.enable_bounce_handling ? 1 : 0
  name  = "${var.configuration_set_name}-notifications"

  tags = var.tags
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "ses_notifications" {
  count = var.enable_bounce_handling ? 1 : 0
  arn   = aws_sns_topic.ses_notifications[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.ses_notifications[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# SES Template for lead notifications
resource "aws_ses_template" "lead_notification" {
  name    = var.lead_notification_template_name
  subject = var.lead_notification_subject
  html    = var.lead_notification_html_template
  text    = var.lead_notification_text_template
}

# SES Template for welcome emails (optional)
resource "aws_ses_template" "welcome_email" {
  count   = var.enable_welcome_email ? 1 : 0
  name    = var.welcome_email_template_name
  subject = var.welcome_email_subject
  html    = var.welcome_email_html_template
  text    = var.welcome_email_text_template
}

# IAM Role for SES sending (for Lambda functions)
resource "aws_iam_role" "ses_sending_role" {
  count = var.create_sending_role ? 1 : 0
  name  = "${var.configuration_set_name}-ses-sending-role"

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

# IAM Policy for SES sending
resource "aws_iam_role_policy" "ses_sending_policy" {
  count = var.create_sending_role ? 1 : 0
  name  = "${var.configuration_set_name}-ses-sending-policy"
  role  = aws_iam_role.ses_sending_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
          "ses:SendTemplatedEmail"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ses:FromAddress" = var.sender_emails
          }
        }
      }
    ]
  })
}

# CloudWatch Log Group for SES events
resource "aws_cloudwatch_log_group" "ses_events" {
  count             = var.enable_cloudwatch_logging ? 1 : 0
  name              = "/aws/ses/${var.configuration_set_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# SES Event Destination for CloudWatch
resource "aws_ses_event_destination" "cloudwatch" {
  count                  = var.enable_cloudwatch_logging ? 1 : 0
  name                   = "${var.configuration_set_name}-cloudwatch"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types         = ["send", "reject", "bounce", "complaint", "delivery"]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "MessageTag"
    value_source   = "messageTag"
  }
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "bounce_rate" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.configuration_set_name}-bounce-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Bounce"
  namespace           = "AWS/SES"
  period              = "300"
  statistic           = "Average"
  threshold           = var.bounce_rate_threshold
  alarm_description   = "This metric monitors SES bounce rate"

  dimensions = {
    ConfigurationSet = aws_ses_configuration_set.main.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "complaint_rate" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.configuration_set_name}-complaint-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Complaint"
  namespace           = "AWS/SES"
  period              = "300"
  statistic           = "Average"
  threshold           = var.complaint_rate_threshold
  alarm_description   = "This metric monitors SES complaint rate"

  dimensions = {
    ConfigurationSet = aws_ses_configuration_set.main.name
  }

  tags = var.tags
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}