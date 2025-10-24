# Production Lead Capture Setup Outputs

# API Gateway Outputs
output "api_gateway_url" {
  description = "URL of the API Gateway endpoint"
  value       = module.api_gateway.api_gateway_url
}

output "custom_domain_url" {
  description = "URL of the custom domain"
  value       = module.api_gateway.custom_domain_url
}

output "api_key_value" {
  description = "API key for form authentication"
  value       = module.api_gateway.api_key_value
  sensitive   = true
}

output "api_gateway_id" {
  description = "ID of the API Gateway for monitoring"
  value       = module.api_gateway.api_gateway_id
}

# DynamoDB Outputs
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table storing leads"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.dynamodb.table_arn
}

output "dynamodb_stream_arn" {
  description = "ARN of the DynamoDB stream (if enabled)"
  value       = module.dynamodb.table_stream_arn
}

output "dynamodb_kms_key_id" {
  description = "KMS key ID used for DynamoDB encryption"
  value       = module.dynamodb.kms_key_id
}

# Lambda Outputs
output "lambda_functions" {
  description = "Information about deployed Lambda functions"
  value = {
    submit_lead = {
      name = module.lambda.submit_lambda_function_name
      arn  = module.lambda.submit_lambda_function_arn
    }
    get_leads = {
      name = module.lambda.get_lambda_function_name
      arn  = module.lambda.get_lambda_function_arn
    }
  }
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.lambda.lambda_execution_role_arn
}

output "lambda_log_groups" {
  description = "CloudWatch log groups for Lambda functions"
  value = {
    submit_lead = module.lambda.submit_lambda_log_group_name
    get_leads   = module.lambda.get_lambda_log_group_name
  }
}

# SES Outputs (if enabled)
output "ses_configuration" {
  description = "SES configuration details"
  value = var.enable_email_notifications ? {
    configuration_set_name        = module.ses[0].configuration_set_name
    domain_verification_token     = module.ses[0].domain_identity_verification_token
    dkim_tokens                  = module.ses[0].dkim_tokens
    sns_topic_arn                = module.ses[0].sns_topic_arn
    lead_notification_template   = module.ses[0].lead_notification_template_name
    welcome_email_template       = module.ses[0].welcome_email_template_name
    ses_sending_role_arn         = module.ses[0].ses_sending_role_arn
  } : null
}

# Monitoring Outputs
output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.lead_capture.dashboard_name}"
}

output "sns_alerts_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarms created for monitoring"
  value = {
    high_error_rate     = aws_cloudwatch_metric_alarm.high_error_rate.alarm_name
    dynamodb_throttling = aws_cloudwatch_metric_alarm.dynamodb_throttling.alarm_name
  }
}

# Integration Outputs
output "form_integration_config" {
  description = "Configuration for integrating the lead capture form"
  value = {
    api_endpoint = var.custom_domain_name != "" ? "https://${var.custom_domain_name}/leads" : "${module.api_gateway.api_gateway_url}/leads"
    api_key_required = true
    cors_origin = var.cors_allow_origin
    supported_fields = ["name", "email", "company", "phone", "message"]
  }
}

output "form_integration_example" {
  description = "Example HTML code for embedding the lead capture form"
  value = <<-EOT
    <!-- Lead Capture Form Integration -->
    <script src="https://your-cdn.com/lead-capture.js"></script>
    <div id="lead-capture-form" 
         data-api-endpoint="${var.custom_domain_name != "" ? "https://${var.custom_domain_name}/leads" : "${module.api_gateway.api_gateway_url}/leads"}"
         data-api-key="[USE_OUTPUT_api_key_value]"
         data-fields="name,email,company,phone,message"
         data-success-message="Thank you! We'll be in touch soon."
         data-error-message="Sorry, there was an error. Please try again.">
    </div>
  EOT
}

# DNS Configuration Outputs
output "dns_configuration" {
  description = "DNS records that need to be configured"
  value = var.enable_email_notifications && var.ses_domain_name != "" ? {
    domain_verification = {
      type  = "TXT"
      name  = "_amazonses.${var.ses_domain_name}"
      value = module.ses[0].domain_identity_verification_token
    }
    dkim_records = [
      for token in module.ses[0].dkim_tokens : {
        type  = "CNAME"
        name  = "${token}._domainkey.${var.ses_domain_name}"
        value = "${token}.dkim.amazonses.com"
      }
    ]
    mail_from_mx = var.mail_from_domain != "" ? {
      type     = "MX"
      name     = var.mail_from_domain
      value    = "10 feedback-smtp.${var.aws_region}.amazonses.com"
      priority = 10
    } : null
    mail_from_spf = var.mail_from_domain != "" ? {
      type  = "TXT"
      name  = var.mail_from_domain
      value = "v=spf1 include:amazonses.com ~all"
    } : null
    api_domain = var.custom_domain_name != "" ? {
      type  = "CNAME"
      name  = var.custom_domain_name
      value = "[API_GATEWAY_DOMAIN_NAME]"  # This would be populated after deployment
    } : null
  } : null
}

# Security and Compliance Outputs
output "security_features" {
  description = "Security features enabled in this deployment"
  value = {
    dynamodb_encryption        = true
    dynamodb_point_in_time_recovery = true
    api_key_authentication    = true
    cors_protection          = var.cors_allow_origin != "*"
    lambda_iam_least_privilege = true
    cloudwatch_monitoring    = true
    ses_dkim_enabled        = var.enable_email_notifications
    ttl_data_retention      = var.enable_data_retention
    kms_key_rotation        = true
  }
}

output "compliance_features" {
  description = "Compliance features for data protection"
  value = {
    gdpr_ttl_enabled           = var.enable_data_retention
    audit_logging             = true
    encryption_at_rest        = true
    encryption_in_transit     = true
    data_backup_enabled       = true
    point_in_time_recovery    = true
  }
}

# Cost Optimization Outputs
output "cost_optimization_recommendations" {
  description = "Recommendations for cost optimization"
  value = {
    dynamodb_billing_mode = var.use_provisioned_capacity ? "PROVISIONED" : "PAY_PER_REQUEST"
    lambda_memory_size   = "512MB (optimized for performance)"
    log_retention_days   = "90 days (production setting)"
    monitoring_enabled   = "Full monitoring enabled"
    recommendations = [
      var.use_provisioned_capacity ? "Monitor DynamoDB utilization and adjust capacity as needed" : "Consider provisioned capacity if usage becomes predictable",
      "Review CloudWatch log retention policies periodically",
      "Monitor API Gateway usage patterns for optimization opportunities",
      "Consider Lambda provisioned concurrency for consistent performance if needed"
    ]
  }
}

# Operational Outputs
output "operational_endpoints" {
  description = "Important endpoints for operations and monitoring"
  value = {
    api_endpoint           = var.custom_domain_name != "" ? "https://${var.custom_domain_name}" : module.api_gateway.api_gateway_url
    cloudwatch_dashboard   = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.lead_capture.dashboard_name}"
    dynamodb_console      = "https://${var.aws_region}.console.aws.amazon.com/dynamodbv2/home?region=${var.aws_region}#table?name=${module.dynamodb.table_name}"
    lambda_console        = "https://${var.aws_region}.console.aws.amazon.com/lambda/home?region=${var.aws_region}#/functions"
    ses_console           = var.enable_email_notifications ? "https://${var.aws_region}.console.aws.amazon.com/ses/home?region=${var.aws_region}#/configuration-sets" : null
  }
}

# Backup and Recovery Outputs
output "backup_and_recovery" {
  description = "Backup and recovery configuration"
  value = {
    dynamodb_point_in_time_recovery = true
    dynamodb_backup_retention      = "35 days (automatic)"
    lambda_code_backup            = "Stored in deployment artifacts"
    terraform_state_backup        = "Ensure Terraform state is backed up"
    recovery_procedures = [
      "DynamoDB: Use point-in-time recovery for data restoration",
      "Lambda: Redeploy from source code and deployment artifacts",
      "API Gateway: Recreate from Terraform configuration",
      "SES: Re-verify domains and recreate templates if needed"
    ]
  }
}