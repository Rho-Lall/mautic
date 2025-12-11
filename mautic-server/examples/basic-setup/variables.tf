# Variables for Basic Mautic Deployment Example

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "mautic-example"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Database Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

# ECS Configuration
variable "task_cpu" {
  description = "CPU units for the ECS task"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Memory (MB) for the ECS task"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Desired number of ECS service instances"
  type        = number
  default     = 1
}

# Mautic Configuration
variable "mautic_secret_key" {
  description = "Secret key for Mautic application"
  type        = string
  sensitive   = true
}

variable "trusted_hosts" {
  description = "Comma-separated list of trusted hosts for Mautic"
  type        = string
  default     = ""
}

# SSL Configuration (optional)
variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS (optional)"
  type        = string
  default     = null
}

# Monitoring Configuration
variable "enable_monitoring_alerts" {
  description = "Enable CloudWatch alarms and SNS notifications"
  type        = bool
  default     = false
}