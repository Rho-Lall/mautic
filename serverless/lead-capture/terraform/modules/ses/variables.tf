variable "domain_name" {
  description = "Domain name to verify with SES (optional)"
  type        = string
  default     = ""
}

variable "sender_emails" {
  description = "List of email addresses to verify with SES"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for email in var.sender_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All sender emails must be valid email addresses."
  }
}

variable "configuration_set_name" {
  description = "Name of the SES configuration set"
  type        = string
  default     = "lead-capture-config-set"
}

variable "enable_dkim" {
  description = "Enable DKIM signing for the domain"
  type        = bool
  default     = true
}

variable "mail_from_domain" {
  description = "Custom MAIL FROM domain (optional)"
  type        = string
  default     = ""
}

variable "enable_reputation_metrics" {
  description = "Enable reputation metrics for the configuration set"
  type        = bool
  default     = true
}

variable "enable_bounce_handling" {
  description = "Enable bounce and complaint handling via SNS"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logging" {
  description = "Enable CloudWatch logging for SES events"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alarms"
  type        = bool
  default     = true
}

variable "bounce_rate_threshold" {
  description = "Bounce rate threshold for CloudWatch alarm (percentage)"
  type        = number
  default     = 5.0

  validation {
    condition     = var.bounce_rate_threshold >= 0 && var.bounce_rate_threshold <= 100
    error_message = "Bounce rate threshold must be between 0 and 100."
  }
}

variable "complaint_rate_threshold" {
  description = "Complaint rate threshold for CloudWatch alarm (percentage)"
  type        = number
  default     = 0.5

  validation {
    condition     = var.complaint_rate_threshold >= 0 && var.complaint_rate_threshold <= 100
    error_message = "Complaint rate threshold must be between 0 and 100."
  }
}

variable "create_sending_role" {
  description = "Create IAM role for SES sending (for Lambda functions)"
  type        = bool
  default     = false
}

variable "lead_notification_template_name" {
  description = "Name of the lead notification email template"
  type        = string
  default     = "lead-notification"
}

variable "lead_notification_subject" {
  description = "Subject line for lead notification emails"
  type        = string
  default     = "New Lead Captured: {{name}}"
}

variable "lead_notification_html_template" {
  description = "HTML template for lead notification emails"
  type        = string
  default     = <<-EOT
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>New Lead Notification</title>
    </head>
    <body>
        <h2>New Lead Captured</h2>
        <p><strong>Name:</strong> {{name}}</p>
        <p><strong>Email:</strong> {{email}}</p>
        <p><strong>Company:</strong> {{company}}</p>
        <p><strong>Source:</strong> {{source}}</p>
        <p><strong>Timestamp:</strong> {{timestamp}}</p>
        
        {{#if customFields}}
        <h3>Additional Information:</h3>
        <ul>
        {{#each customFields}}
            <li><strong>{{@key}}:</strong> {{this}}</li>
        {{/each}}
        </ul>
        {{/if}}
    </body>
    </html>
  EOT
}

variable "lead_notification_text_template" {
  description = "Text template for lead notification emails"
  type        = string
  default     = <<-EOT
    New Lead Captured
    
    Name: {{name}}
    Email: {{email}}
    Company: {{company}}
    Source: {{source}}
    Timestamp: {{timestamp}}
    
    {{#if customFields}}
    Additional Information:
    {{#each customFields}}
    {{@key}}: {{this}}
    {{/each}}
    {{/if}}
  EOT
}

variable "enable_welcome_email" {
  description = "Enable welcome email template creation"
  type        = bool
  default     = false
}

variable "welcome_email_template_name" {
  description = "Name of the welcome email template"
  type        = string
  default     = "welcome-email"
}

variable "welcome_email_subject" {
  description = "Subject line for welcome emails"
  type        = string
  default     = "Welcome! Thank you for your interest"
}

variable "welcome_email_html_template" {
  description = "HTML template for welcome emails"
  type        = string
  default     = <<-EOT
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Welcome</title>
    </head>
    <body>
        <h2>Thank you for your interest, {{name}}!</h2>
        <p>We've received your information and will be in touch soon.</p>
        <p>Best regards,<br>The Team</p>
    </body>
    </html>
  EOT
}

variable "welcome_email_text_template" {
  description = "Text template for welcome emails"
  type        = string
  default     = <<-EOT
    Thank you for your interest, {{name}}!
    
    We've received your information and will be in touch soon.
    
    Best regards,
    The Team
  EOT
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}