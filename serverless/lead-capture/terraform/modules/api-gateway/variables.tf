variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "lead-capture-api"
}

variable "api_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = "API Gateway for serverless lead capture form"
}

variable "stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "prod"
}

variable "submit_lambda_invoke_arn" {
  description = "Invoke ARN of the submit lead Lambda function"
  type        = string
}

variable "get_lambda_invoke_arn" {
  description = "Invoke ARN of the get leads Lambda function"
  type        = string
}

variable "submit_lambda_function_name" {
  description = "Name of the submit lead Lambda function"
  type        = string
}

variable "get_lambda_function_name" {
  description = "Name of the get leads Lambda function"
  type        = string
}

variable "cors_allow_origin" {
  description = "CORS allowed origin for API requests"
  type        = string
  default     = "'*'"
}

variable "custom_domain_name" {
  description = "Custom domain name for the API Gateway (optional)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for custom domain (required if custom_domain_name is set)"
  type        = string
  default     = ""
}

variable "enable_api_key" {
  description = "Enable API key authentication"
  type        = bool
  default     = true
}

variable "quota_limit" {
  description = "API usage quota limit"
  type        = number
  default     = 10000
}

variable "quota_period" {
  description = "API usage quota period (DAY, WEEK, MONTH)"
  type        = string
  default     = "DAY"

  validation {
    condition     = contains(["DAY", "WEEK", "MONTH"], var.quota_period)
    error_message = "Quota period must be one of: DAY, WEEK, MONTH."
  }
}

variable "throttle_rate_limit" {
  description = "API throttle rate limit (requests per second)"
  type        = number
  default     = 100
}

variable "throttle_burst_limit" {
  description = "API throttle burst limit"
  type        = number
  default     = 200
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}