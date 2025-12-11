# ECS Cluster Module - Variables
# Standard variable patterns for the ECS cluster module

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

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

variable "fargate_base_capacity" {
  description = "Base capacity for Fargate capacity provider"
  type        = number
  default     = 1
  validation {
    condition     = var.fargate_base_capacity >= 0
    error_message = "Fargate base capacity must be non-negative."
  }
}

variable "fargate_weight" {
  description = "Weight for Fargate capacity provider"
  type        = number
  default     = 1
  validation {
    condition     = var.fargate_weight >= 0
    error_message = "Fargate weight must be non-negative."
  }
}

variable "enable_fargate_spot" {
  description = "Enable Fargate Spot capacity provider"
  type        = bool
  default     = false
}

variable "fargate_spot_base_capacity" {
  description = "Base capacity for Fargate Spot capacity provider"
  type        = number
  default     = 0
  validation {
    condition     = var.fargate_spot_base_capacity >= 0
    error_message = "Fargate Spot base capacity must be non-negative."
  }
}

variable "fargate_spot_weight" {
  description = "Weight for Fargate Spot capacity provider"
  type        = number
  default     = 1
  validation {
    condition     = var.fargate_spot_weight >= 0
    error_message = "Fargate Spot weight must be non-negative."
  }
}

# ECS Service Configuration Variables
variable "create_service" {
  description = "Whether to create ECS service and related resources"
  type        = bool
  default     = false
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "app"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.container_name))
    error_message = "Container name must contain only alphanumeric characters, underscores, and hyphens."
  }
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "Container port must be between 1 and 65535."
  }
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Memory (MB) for the task"
  type        = number
  default     = 512
  validation {
    condition     = var.task_memory >= 512 && var.task_memory <= 30720
    error_message = "Task memory must be between 512 and 30720 MB."
  }
}

variable "execution_role_arn" {
  description = "ARN of the task execution role"
  type        = string
  default     = null
}

variable "task_role_arn" {
  description = "ARN of the task role"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
  validation {
    condition     = var.desired_count >= 0
    error_message = "Desired count must be non-negative."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for the service"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for the service"
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the task"
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "ARN of the target group for load balancer integration"
  type        = string
  default     = null
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
  validation {
    condition     = var.health_check_grace_period >= 0 && var.health_check_grace_period <= 2147483647
    error_message = "Health check grace period must be between 0 and 2147483647 seconds."
  }
}

# Note: Deployment configuration variables removed due to provider compatibility
# Users can configure deployment settings through AWS console or CLI if needed

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

# Health Check Variables
variable "enable_health_check" {
  description = "Enable container health check"
  type        = bool
  default     = true
}

variable "health_check_command" {
  description = "Health check command"
  type        = list(string)
  default     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 300
    error_message = "Health check interval must be between 5 and 300 seconds."
  }
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
  validation {
    condition     = var.health_check_timeout >= 2 && var.health_check_timeout <= 60
    error_message = "Health check timeout must be between 2 and 60 seconds."
  }
}

variable "health_check_retries" {
  description = "Number of health check retries"
  type        = number
  default     = 3
  validation {
    condition     = var.health_check_retries >= 1 && var.health_check_retries <= 10
    error_message = "Health check retries must be between 1 and 10."
  }
}

variable "health_check_start_period" {
  description = "Health check start period in seconds"
  type        = number
  default     = 60
  validation {
    condition     = var.health_check_start_period >= 0 && var.health_check_start_period <= 300
    error_message = "Health check start period must be between 0 and 300 seconds."
  }
}

# Auto Scaling Variables
variable "enable_autoscaling" {
  description = "Enable auto scaling for the service"
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