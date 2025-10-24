output "domain_identity_arn" {
  description = "ARN of the SES domain identity (if domain is configured)"
  value       = var.domain_name != "" ? aws_ses_domain_identity.main[0].arn : ""
}

output "domain_identity_verification_token" {
  description = "Verification token for the SES domain identity (if domain is configured)"
  value       = var.domain_name != "" ? aws_ses_domain_identity.main[0].verification_token : ""
}

output "dkim_tokens" {
  description = "DKIM tokens for DNS configuration (if DKIM is enabled)"
  value       = var.domain_name != "" && var.enable_dkim ? aws_ses_domain_dkim.main[0].dkim_tokens : []
}

output "email_identities" {
  description = "Map of verified email identities"
  value = {
    for email, identity in aws_ses_email_identity.sender_emails : email => identity.arn
  }
}

output "configuration_set_name" {
  description = "Name of the SES configuration set"
  value       = aws_ses_configuration_set.main.name
}

output "configuration_set_arn" {
  description = "ARN of the SES configuration set"
  value       = aws_ses_configuration_set.main.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for SES notifications (if bounce handling is enabled)"
  value       = var.enable_bounce_handling ? aws_sns_topic.ses_notifications[0].arn : ""
}

output "sns_topic_name" {
  description = "Name of the SNS topic for SES notifications (if bounce handling is enabled)"
  value       = var.enable_bounce_handling ? aws_sns_topic.ses_notifications[0].name : ""
}

output "lead_notification_template_name" {
  description = "Name of the lead notification email template"
  value       = aws_ses_template.lead_notification.name
}

output "welcome_email_template_name" {
  description = "Name of the welcome email template (if enabled)"
  value       = var.enable_welcome_email ? aws_ses_template.welcome_email[0].name : ""
}

output "ses_sending_role_arn" {
  description = "ARN of the SES sending IAM role (if created)"
  value       = var.create_sending_role ? aws_iam_role.ses_sending_role[0].arn : ""
}

output "ses_sending_role_name" {
  description = "Name of the SES sending IAM role (if created)"
  value       = var.create_sending_role ? aws_iam_role.ses_sending_role[0].name : ""
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for SES events (if enabled)"
  value       = var.enable_cloudwatch_logging ? aws_cloudwatch_log_group.ses_events[0].name : ""
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for SES events (if enabled)"
  value       = var.enable_cloudwatch_logging ? aws_cloudwatch_log_group.ses_events[0].arn : ""
}

output "mail_from_domain" {
  description = "Custom MAIL FROM domain (if configured)"
  value       = var.mail_from_domain
}

output "sender_emails" {
  description = "List of verified sender email addresses"
  value       = var.sender_emails
}

output "bounce_rate_alarm_name" {
  description = "Name of the bounce rate CloudWatch alarm (if monitoring is enabled)"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.bounce_rate[0].alarm_name : ""
}

output "complaint_rate_alarm_name" {
  description = "Name of the complaint rate CloudWatch alarm (if monitoring is enabled)"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.complaint_rate[0].alarm_name : ""
}