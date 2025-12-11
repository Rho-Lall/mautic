# Load Balancer Module - Variables
# Standard variable patterns for the Application Load Balancer module

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

# Network Configuration
variable "vpc_id" {
  description = "VPC ID where the load balancer will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the load balancer"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs must be provided for high availability."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs for the load balancer"
  type        = list(string)
}

variable "internal" {
  description = "Whether the load balancer is internal"
  type        = bool
  default     = false
}

# Load Balancer Configuration
variable "enable_deletion_protection" {
  description = "Enable deletion protection for the load balancer"
  type        = bool
  default     = false
}

variable "enable_http2" {
  description = "Enable HTTP/2 support"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "Connection idle timeout in seconds"
  type        = number
  default     = 60
  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 4000
    error_message = "Idle timeout must be between 1 and 4000 seconds."
  }
}

# Target Group Configuration
variable "target_port" {
  description = "Port on which targets receive traffic"
  type        = number
  default     = 80
  validation {
    condition     = var.target_port > 0 && var.target_port <= 65535
    error_message = "Target port must be between 1 and 65535."
  }
}

variable "target_protocol" {
  description = "Protocol to use for routing traffic to targets"
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.target_protocol)
    error_message = "Target protocol must be HTTP or HTTPS."
  }
}

# Health Check Configuration
variable "health_check_enabled" {
  description = "Enable health checks"
  type        = bool
  default     = true
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive health checks successes required"
  type        = number
  default     = 2
  validation {
    condition     = var.health_check_healthy_threshold >= 2 && var.health_check_healthy_threshold <= 10
    error_message = "Healthy threshold must be between 2 and 10."
  }
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 2
  validation {
    condition     = var.health_check_unhealthy_threshold >= 2 && var.health_check_unhealthy_threshold <= 10
    error_message = "Unhealthy threshold must be between 2 and 10."
  }
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
  validation {
    condition     = var.health_check_timeout >= 2 && var.health_check_timeout <= 120
    error_message = "Health check timeout must be between 2 and 120 seconds."
  }
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

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "health_check_matcher" {
  description = "HTTP response codes to consider healthy"
  type        = string
  default     = "200"
}

variable "health_check_protocol" {
  description = "Protocol for health checks"
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.health_check_protocol)
    error_message = "Health check protocol must be HTTP or HTTPS."
  }
}

variable "health_check_port" {
  description = "Port for health checks (traffic-port or specific port)"
  type        = string
  default     = "traffic-port"
}

# SSL Configuration
variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener"
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "enable_https_redirect" {
  description = "Enable HTTP to HTTPS redirect"
  type        = bool
  default     = true
}

variable "enable_security_headers" {
  description = "Enable security headers in responses"
  type        = bool
  default     = true
}

variable "security_headers" {
  description = "Security headers to add to responses"
  type        = map(string)
  default = {
    "Strict-Transport-Security" = "max-age=31536000; includeSubDomains"
    "X-Content-Type-Options"    = "nosniff"
    "X-Frame-Options"           = "DENY"
    "X-XSS-Protection"          = "1; mode=block"
    "Referrer-Policy"           = "strict-origin-when-cross-origin"
    "Content-Security-Policy"   = "default-src 'self'"
  }
}

# Security Configuration
variable "drop_invalid_header_fields" {
  description = "Drop invalid header fields to improve security"
  type        = bool
  default     = true
}

# Access Logs Configuration
variable "enable_access_logs" {
  description = "Enable access logs for the load balancer"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for access logs"
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "S3 prefix for access logs"
  type        = string
  default     = null
}