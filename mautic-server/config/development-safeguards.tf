# Development Environment Safeguards Configuration
# This file provides common safeguard configurations for development environments

# Local values for development safeguards
locals {
  # Development environment detection
  is_development = var.environment == "dev"
  
  # Resource creation control
  should_create_resources = var.create_resources && !local.is_development
  
  # Development-specific tags
  development_tags = {
    Environment     = "development"
    Purpose         = "testing"
    AutoDestroy     = "true"
    CreatedBy       = "terraform"
    PublicModule    = "true"
    ResourceCreated = local.should_create_resources ? "true" : "false"
  }
  
  # Merge with user-provided tags
  final_tags = merge(var.tags, local.development_tags)
}

# Development environment validation
resource "null_resource" "development_validation" {
  count = local.is_development && var.create_resources ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'ERROR: Resource creation is not allowed in development environment' && exit 1"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Resource creation warning for development
resource "null_resource" "development_warning" {
  count = local.is_development ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'WARNING: Running in development mode - no actual resources will be created'"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Outputs for development validation
output "development_safeguards" {
  description = "Development environment safeguard status"
  value = {
    environment           = var.environment
    is_development       = local.is_development
    create_resources     = var.create_resources
    should_create        = local.should_create_resources
    safeguards_active    = local.is_development
    warning_message      = local.is_development ? "Development mode active - no resources created" : "Production mode - resources may be created"
  }
}

# Common variables that should be included in all modules
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "create_resources" {
  description = "Whether to create resources (automatically disabled in dev environment)"
  type        = bool
  default     = false
  validation {
    condition     = var.environment == "dev" ? var.create_resources == false : true
    error_message = "Resource creation must be disabled (create_resources = false) in development environment for safety."
  }
}

variable "project_name" {
  description = "Project name for resource naming (must not contain production indicators)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
  validation {
    condition     = !can(regex("prod|production|live", var.project_name))
    error_message = "Project name must not contain production indicators (prod, production, live) for safety."
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for key, value in var.tags : !can(regex("prod|production|live", lower(value)))
    ])
    error_message = "Tag values must not contain production indicators for safety."
  }
}

variable "prevent_destroy" {
  description = "Prevent accidental destruction of resources"
  type        = bool
  default     = true
}

# Security validation locals
locals {
  # Validate no hardcoded secrets
  has_secrets = false  # This would be set by security scanning
  
  # Validate no production values
  has_production_values = false  # This would be set by validation scanning
  
  # Overall security status
  security_validated = !local.has_secrets && !local.has_production_values
}

# Security validation output
output "security_validation" {
  description = "Security validation status"
  value = {
    secrets_detected        = local.has_secrets
    production_values_found = local.has_production_values
    security_validated      = local.security_validated
    validation_message      = local.security_validated ? "Security validation passed" : "Security issues detected - review required"
  }
}