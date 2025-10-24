# Variables for the basic lead capture setup example

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "submit_lambda_zip_path" {
  description = "Path to the submit lead Lambda function ZIP file"
  type        = string
  default     = "../../../dist/submit-lead.zip"
}

variable "get_lambda_zip_path" {
  description = "Path to the get leads Lambda function ZIP file"
  type        = string
  default     = "../../../dist/get-leads.zip"
}

variable "cors_allow_origin" {
  description = "CORS allowed origin for API requests"
  type        = string
  default     = "*"
}

variable "enable_api_key" {
  description = "Enable API key authentication"
  type        = bool
  default     = true
}

variable "custom_domain_name" {
  description = "Custom domain name for the API Gateway (optional)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for custom domain"
  type        = string
  default     = ""
}

variable "enable_email_notifications" {
  description = "Enable SES email notifications"
  type        = bool
  default     = false
}

variable "sender_emails" {
  description = "List of verified sender email addresses"
  type        = list(string)
  default     = []
}

variable "ses_domain_name" {
  description = "Domain name for SES verification"
  type        = string
  default     = ""
}

variable "mail_from_domain" {
  description = "Custom MAIL FROM domain for SES"
  type        = string
  default     = ""
}

variable "enable_welcome_email" {
  description = "Enable welcome email template"
  type        = bool
  default     = false
}