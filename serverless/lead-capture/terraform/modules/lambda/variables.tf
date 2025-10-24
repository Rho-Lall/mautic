variable "function_name_prefix" {
  description = "Prefix for Lambda function names"
  type        = string
  default     = "lead-capture"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs18.x"

  validation {
    condition = contains([
      "nodejs14.x", "nodejs16.x", "nodejs18.x", "nodejs20.x",
      "python3.8", "python3.9", "python3.10", "python3.11"
    ], var.runtime)
    error_message = "Runtime must be a supported Lambda runtime version."
  }
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 256

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 and 10240 MB."
  }
}

variable "submit_lambda_zip_path" {
  description = "Path to the submit lead Lambda function ZIP file"
  type        = string
}

variable "get_lambda_zip_path" {
  description = "Path to the get leads Lambda function ZIP file"
  type        = string
}

variable "submit_lambda_handler" {
  description = "Handler for the submit lead Lambda function"
  type        = string
  default     = "submit-lead.handler"
}

variable "get_lambda_handler" {
  description = "Handler for the get leads Lambda function"
  type        = string
  default     = "get-leads.handler"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for storing leads"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for storing leads"
  type        = string
}

variable "cors_allow_origin" {
  description = "CORS allowed origin for API requests"
  type        = string
  default     = "*"
}

variable "log_level" {
  description = "Log level for Lambda functions"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARN, ERROR."
  }
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

variable "enable_ses" {
  description = "Enable SES permissions for Lambda functions"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alarms"
  type        = bool
  default     = true
}

variable "submit_lambda_environment_variables" {
  description = "Additional environment variables for submit lead Lambda function"
  type        = map(string)
  default     = {}
}

variable "get_lambda_environment_variables" {
  description = "Additional environment variables for get leads Lambda function"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}