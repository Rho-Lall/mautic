# Mautic Service Module - Variables
# Standard variable patterns for the Mautic ECS service module

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
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# ECS Configuration
variable "ecs_cluster_id" {
  description = "ECS cluster ID where the service will be deployed"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for auto-scaling configuration"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS service"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN for load balancer integration"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name for container logs"
  type        = string
}

# Task Configuration
variable "task_cpu" {
  description = "CPU units for the ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Task CPU must be 256, 512, 1024, 2048, or 4096."
  }
}

variable "task_memory" {
  description = "Memory (MB) for the ECS task"
  type        = number
  default     = 1024
  validation {
    condition     = var.task_memory >= 512 && var.task_memory <= 30720
    error_message = "Task memory must be between 512 and 30720 MB."
  }
}

variable "desired_count" {
  description = "Desired number of ECS service instances"
  type        = number
  default     = 1
  validation {
    condition     = var.desired_count >= 0
    error_message = "Desired count must be non-negative."
  }
}

variable "container_port" {
  description = "Port on which the Mautic container listens"
  type        = number
  default     = 80
  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "Container port must be between 1 and 65535."
  }
}

# Mautic Configuration
variable "mautic_image" {
  description = "Mautic Docker image to use"
  type        = string
  default     = "mautic/mautic:latest"
}

variable "database_host" {
  description = "Database host endpoint"
  type        = string
}

variable "database_port" {
  description = "Database port"
  type        = number
  default     = 3306
  validation {
    condition     = var.database_port > 0 && var.database_port <= 65535
    error_message = "Database port must be between 1 and 65535."
  }
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "mautic"
}

variable "database_user" {
  description = "Database username"
  type        = string
  default     = "mautic_admin"
}

variable "database_password_secret_arn" {
  description = "ARN of the secret containing the database password"
  type        = string
}

variable "secret_key_secret_arn" {
  description = "ARN of the secret containing the Mautic secret key"
  type        = string
}

variable "trusted_hosts" {
  description = "Comma-separated list of trusted hosts for Mautic"
  type        = string
  default     = ""
}

variable "enable_cron_jobs" {
  description = "Enable Mautic cron jobs in the container"
  type        = bool
  default     = true
}

variable "additional_environment_variables" {
  description = "Additional environment variables for the Mautic container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Note: Deployment configuration variables removed due to provider compatibility
# Users can configure deployment settings through AWS console or CLI if needed

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = false
}

# Auto Scaling Variables
variable "enable_autoscaling" {
  description = "Enable auto scaling for the Mautic service"
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks for auto scaling"
  type        = number
  default     = 1
  validation {
    condition     = var.autoscaling_min_capacity >= 1
    error_message = "Auto scaling minimum capacity must be at least 1."
  }
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks for auto scaling"
  type        = number
  default     = 10
  validation {
    condition     = var.autoscaling_max_capacity >= 1
    error_message = "Auto scaling maximum capacity must be at least 1."
  }
}

variable "enable_cpu_scaling" {
  description = "Enable CPU-based auto scaling"
  type        = bool
  default     = true
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for auto scaling"
  type        = number
  default     = 70
  validation {
    condition     = var.cpu_target_value > 0 && var.cpu_target_value <= 100
    error_message = "CPU target value must be between 0 and 100."
  }
}

variable "enable_memory_scaling" {
  description = "Enable memory-based auto scaling"
  type        = bool
  default     = false
}

variable "memory_target_value" {
  description = "Target memory utilization percentage for auto scaling"
  type        = number
  default     = 80
  validation {
    condition     = var.memory_target_value > 0 && var.memory_target_value <= 100
    error_message = "Memory target value must be between 0 and 100."
  }
}