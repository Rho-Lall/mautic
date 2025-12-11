# Networking Module - Variables
# Standard variable patterns for the VPC and networking module

# Security Safeguards
variable "create_resources" {
  description = "Whether to create resources (set to false for development/testing)"
  type        = bool
  default     = false
}

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

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

# Subnet Configuration
variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
  validation {
    condition     = var.public_subnet_count >= 1 && var.public_subnet_count <= 6
    error_message = "Public subnet count must be between 1 and 6."
  }
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
  validation {
    condition     = var.private_subnet_count >= 1 && var.private_subnet_count <= 6
    error_message = "Private subnet count must be between 1 and 6."
  }
}

variable "subnet_newbits" {
  description = "Number of additional bits to extend the VPC CIDR for subnets"
  type        = number
  default     = 8
  validation {
    condition     = var.subnet_newbits >= 1 && var.subnet_newbits <= 16
    error_message = "Subnet newbits must be between 1 and 16."
  }
}

# NAT Gateway Configuration
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways to create"
  type        = number
  default     = 1
  validation {
    condition     = var.nat_gateway_count >= 1 && var.nat_gateway_count <= 6
    error_message = "NAT Gateway count must be between 1 and 6."
  }
}

# Security Group Configuration
variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  validation {
    condition = alltrue([
      for cidr in var.alb_ingress_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All ALB ingress CIDR blocks must be valid IPv4 CIDR blocks."
  }
}

variable "container_port" {
  description = "Port on which the container receives traffic"
  type        = number
  default     = 80
  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "Container port must be between 1 and 65535."
  }
}