variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "lead-capture-leads"
}

variable "billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.billing_mode)
    error_message = "Billing mode must be either PROVISIONED or PAY_PER_REQUEST."
  }
}

variable "hash_key" {
  description = "Hash key (partition key) for the DynamoDB table"
  type        = string
  default     = "leadId"
}

variable "range_key" {
  description = "Range key (sort key) for the DynamoDB table"
  type        = string
  default     = "timestamp"
}

variable "read_capacity" {
  description = "Read capacity units for the table (only used with PROVISIONED billing)"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Write capacity units for the table (only used with PROVISIONED billing)"
  type        = number
  default     = 5
}

variable "gsi_read_capacity" {
  description = "Read capacity units for GSI (only used with PROVISIONED billing)"
  type        = number
  default     = 5
}

variable "gsi_write_capacity" {
  description = "Write capacity units for GSI (only used with PROVISIONED billing)"
  type        = number
  default     = 5
}

variable "enable_encryption" {
  description = "Enable encryption at rest using KMS"
  type        = bool
  default     = true
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7

  validation {
    condition     = var.kms_deletion_window >= 7 && var.kms_deletion_window <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "enable_ttl" {
  description = "Enable TTL for automatic item expiration"
  type        = bool
  default     = false
}

variable "ttl_attribute" {
  description = "Attribute name for TTL"
  type        = string
  default     = "expiresAt"
}

variable "enable_streams" {
  description = "Enable DynamoDB streams"
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "Stream view type (KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES)"
  type        = string
  default     = "NEW_AND_OLD_IMAGES"

  validation {
    condition = contains([
      "KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"
    ], var.stream_view_type)
    error_message = "Stream view type must be one of: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES."
  }
}

variable "enable_backup" {
  description = "Enable automatic backup creation"
  type        = bool
  default     = false
}

variable "enable_autoscaling" {
  description = "Enable auto scaling for provisioned capacity"
  type        = bool
  default     = false
}

variable "read_min_capacity" {
  description = "Minimum read capacity for auto scaling"
  type        = number
  default     = 5
}

variable "read_max_capacity" {
  description = "Maximum read capacity for auto scaling"
  type        = number
  default     = 100
}

variable "write_min_capacity" {
  description = "Minimum write capacity for auto scaling"
  type        = number
  default     = 5
}

variable "write_max_capacity" {
  description = "Maximum write capacity for auto scaling"
  type        = number
  default     = 100
}

variable "read_target_utilization" {
  description = "Target utilization percentage for read capacity auto scaling"
  type        = number
  default     = 70

  validation {
    condition     = var.read_target_utilization >= 20 && var.read_target_utilization <= 90
    error_message = "Read target utilization must be between 20 and 90 percent."
  }
}

variable "write_target_utilization" {
  description = "Target utilization percentage for write capacity auto scaling"
  type        = number
  default     = 70

  validation {
    condition     = var.write_target_utilization >= 20 && var.write_target_utilization <= 90
    error_message = "Write target utilization must be between 20 and 90 percent."
  }
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alarms"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}