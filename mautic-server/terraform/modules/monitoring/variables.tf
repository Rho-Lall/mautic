# Monitoring Module - Variables
# Standard variable patterns for the CloudWatch monitoring module

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region for CloudWatch dashboard"
  type        = string
  default     = "us-east-1"
}

# Log Configuration
variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 7
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

# Resource References
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster for monitoring"
  type        = string
  default     = ""
}

variable "ecs_service_name" {
  description = "Name of the ECS service for monitoring"
  type        = string
  default     = ""
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer for monitoring"
  type        = string
  default     = ""
}

variable "rds_instance_id" {
  description = "RDS instance identifier for monitoring"
  type        = string
  default     = ""
}

# Alert Configuration
variable "enable_alerts" {
  description = "Enable CloudWatch alarms and SNS notifications"
  type        = bool
  default     = false
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for ECS alarms (percentage)"
  type        = number
  default     = 80
  validation {
    condition     = var.cpu_alarm_threshold >= 0 && var.cpu_alarm_threshold <= 100
    error_message = "CPU alarm threshold must be between 0 and 100."
  }
}

variable "memory_alarm_threshold" {
  description = "Memory utilization threshold for ECS alarms (percentage)"
  type        = number
  default     = 80
  validation {
    condition     = var.memory_alarm_threshold >= 0 && var.memory_alarm_threshold <= 100
    error_message = "Memory alarm threshold must be between 0 and 100."
  }
}

variable "response_time_alarm_threshold" {
  description = "Response time threshold for ALB alarms (seconds)"
  type        = number
  default     = 2
  validation {
    condition     = var.response_time_alarm_threshold > 0
    error_message = "Response time alarm threshold must be greater than 0."
  }
}

variable "rds_cpu_alarm_threshold" {
  description = "CPU utilization threshold for RDS alarms (percentage)"
  type        = number
  default     = 80
  validation {
    condition     = var.rds_cpu_alarm_threshold >= 0 && var.rds_cpu_alarm_threshold <= 100
    error_message = "RDS CPU alarm threshold must be between 0 and 100."
  }
}