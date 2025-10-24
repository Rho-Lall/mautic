# Production Lead Capture Setup Variables

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

# Lambda Configuration
variable "submit_lambda_zip_path" {
  description = "Path to the submit lead Lambda function ZIP file"
  type        = string
}

variable "get_lambda_zip_path" {
  description = "Path to the get leads Lambda function ZIP file"
  type        = string
}

variable "submit_lambda_environment_variables" {
  description = "Additional environment variables for submit Lambda function"
  type        = map(string)
  default     = {}
}

variable "get_lambda_environment_variables" {
  description = "Additional environment variables for get Lambda function"
  type        = map(string)
  default     = {}
}

# DynamoDB Configuration
variable "use_provisioned_capacity" {
  description = "Use provisioned capacity instead of pay-per-request"
  type        = bool
  default     = false
}

variable "initial_read_capacity" {
  description = "Initial read capacity units for DynamoDB table"
  type        = number
  default     = 10
}

variable "initial_write_capacity" {
  description = "Initial write capacity units for DynamoDB table"
  type        = number
  default     = 10
}

variable "gsi_read_capacity" {
  description = "Read capacity units for Global Secondary Indexes"
  type        = number
  default     = 5
}

variable "gsi_write_capacity" {
  description = "Write capacity units for Global Secondary Indexes"
  type        = number
  default     = 5
}

variable "read_min_capacity" {
  description = "Minimum read capacity for auto scaling"
  type        = number
  default     = 5
}

variable "read_max_capacity" {
  description = "Maximum read capacity for auto scaling"
  type        = number
  default     = 200
}

variable "write_min_capacity" {
  description = "Minimum write capacity for auto scaling"
  type        = number
  default     = 5
}

variable "write_max_capacity" {
  description = "Maximum write capacity for auto scaling"
  type        = number
  default     = 200
}

variable "enable_data_retention" {
  description = "Enable TTL for automatic data expiration (GDPR compliance)"
  type        = bool
  default     = true
}

variable "enable_real_time_processing" {
  description = "Enable DynamoDB streams for real-time processing"
  type        = bool
  default     = false
}

# API Gateway Configuration
variable "cors_allow_origin" {
  description = "CORS allowed origin for API requests"
  type        = string
  validation {
    condition     = can(regex("^https://", var.cors_allow_origin)) || var.cors_allow_origin == "*"
    error_message = "CORS origin must be HTTPS URL or '*' for development."
  }
}

variable "custom_domain_name" {
  description = "Custom domain name for the API Gateway"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for custom domain"
  type        = string
}

variable "daily_quota_limit" {
  description = "Daily API usage quota limit"
  type        = number
  default     = 50000
}

variable "throttle_rate_limit" {
  description = "API throttle rate limit (requests per second)"
  type        = number
  default     = 200
}

variable "throttle_burst_limit" {
  description = "API throttle burst limit"
  type        = number
  default     = 400
}

# SES Configuration
variable "enable_email_notifications" {
  description = "Enable SES email notifications"
  type        = bool
  default     = true
}

variable "ses_domain_name" {
  description = "Domain name for SES verification"
  type        = string
  default     = ""
}

variable "sender_emails" {
  description = "List of verified sender email addresses"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for email in var.sender_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All sender emails must be valid email addresses."
  }
}

variable "mail_from_domain" {
  description = "Custom MAIL FROM domain for SES"
  type        = string
  default     = ""
}

variable "enable_welcome_email" {
  description = "Enable welcome email template"
  type        = bool
  default     = true
}

variable "website_name" {
  description = "Name of the website for email templates"
  type        = string
  default     = "Our Website"
}

variable "company_name" {
  description = "Company name for email templates"
  type        = string
  default     = "Our Company"
}

variable "custom_notification_template" {
  description = "Custom HTML template for lead notifications (optional)"
  type        = string
  default     = ""
}

variable "custom_welcome_template" {
  description = "Custom HTML template for welcome emails (optional)"
  type        = string
  default     = ""
}

# Monitoring Configuration
variable "alert_email_addresses" {
  description = "Email addresses to receive CloudWatch alerts"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for email in var.alert_email_addresses : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All alert email addresses must be valid email addresses."
  }
}