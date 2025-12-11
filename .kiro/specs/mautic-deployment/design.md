# Design Document

## Overview

This design outlines the creation of reusable, open-source Terraform modules and a vanilla Docker configuration for deploying Mautic marketing automation platform on AWS infrastructure. The design focuses on providing generic, secure templates that developers can customize for their own deployments without exposing any sensitive information or creating actual AWS resources in the public repository.

## Architecture

The public modules will follow a modular architecture where each component can be used independently or combined with others. The design emphasizes security, reusability, and flexibility while maintaining a clear separation between public templates and private implementations.

```
Public Modules Architecture:
├── Terraform Modules (Infrastructure Templates)
│   ├── ECS Module (Container Orchestration)
│   ├── RDS Module (Database Layer)
│   ├── ALB Module (Load Balancing)
│   ├── VPC Module (Networking)
│   └── Monitoring Module (CloudWatch)
└── Docker Configuration (Application Layer)
    └── Vanilla Mautic Container
```

## Components and Interfaces

### Directory Structure

```
public-modules/mautic-server/
├── terraform/
│   └── modules/
│       ├── ecs-cluster/          # ECS Fargate service templates
│       ├── mautic-service/       # Mautic-specific ECS configuration
│       ├── database/             # RDS MySQL templates
│       ├── load-balancer/        # ALB configuration templates
│       ├── networking/           # VPC, subnets, security groups
│       └── monitoring/           # CloudWatch dashboards and alarms
└── docker/
    ├── Dockerfile               # Vanilla Mautic container
    └── config/                  # Basic configuration templates
```

### Terraform Module Interfaces

Each Terraform module will expose a consistent interface pattern:

**Input Variables:**
- Environment-specific configurations (via variables)
- Resource naming patterns (via variables)
- Security configurations (via variables)
- Feature toggles (via variables)

**Output Values:**
- Resource identifiers for module interconnection
- Connection endpoints
- Security group IDs
- Network configuration details

**Module Interconnection:**
- Modules communicate through output/input variable chains
- No hardcoded dependencies between modules
- Clear data flow patterns for resource references

### Docker Configuration Interface

**Vanilla Mautic Container:**
- Extends official Mautic image without modifications
- Environment variable-based configuration
- Health check endpoints
- Standard logging configuration
- No custom plugins or themes

## Data Models

### Terraform Variable Schema

```hcl
# Common variable patterns across all modules
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
```

### Module Output Schema

```hcl
# Standard output pattern for all modules
output "resource_id" {
  description = "Primary resource identifier"
  value       = aws_resource.main.id
}

output "resource_arn" {
  description = "Resource ARN for cross-module references"
  value       = aws_resource.main.arn
}

output "connection_info" {
  description = "Connection details for other modules"
  value = {
    endpoint = aws_resource.main.endpoint
    port     = aws_resource.main.port
  }
  sensitive = true
}
```

### Docker Environment Variables

```dockerfile
# Standard environment variables for Mautic configuration
ENV MAUTIC_DB_HOST=""
ENV MAUTIC_DB_PORT="3306"
ENV MAUTIC_DB_NAME=""
ENV MAUTIC_DB_USER=""
ENV MAUTIC_DB_PASSWORD=""
ENV MAUTIC_TRUSTED_HOSTS=""
ENV MAUTIC_SECRET_KEY=""
```
## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Terraform Module Validity
*For any* Terraform module in the public modules, the module should produce valid Terraform configuration that can be validated and planned without errors
**Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5**

### Property 2: Docker Configuration Validity
*For any* Docker configuration file, the file should extend the official Mautic image and include required environment variables and health checks
**Validates: Requirements 2.1, 2.2, 2.3**

### Property 3: Vanilla Container Purity
*For any* Docker configuration, the container should not include custom plugins, themes, or non-essential modifications beyond the official Mautic image
**Validates: Requirements 2.4, 2.5**

### Property 4: Module Independence
*For any* Terraform module, the module should be usable independently without requiring other modules as dependencies
**Validates: Requirements 3.1**

### Property 5: Module Interface Consistency
*For any* Terraform module, the module should expose required output variables and accept required input variables following the standard interface pattern
**Validates: Requirements 3.2, 3.3**

### Property 6: Input Validation Completeness
*For any* Terraform module variable, the variable should include appropriate type definitions and validation rules to prevent configuration errors
**Validates: Requirements 3.4, 3.5**

### Property 7: Security Configuration Compliance
*For any* security-related resource configuration, the configuration should implement least-privilege access patterns and enable encryption by default
**Validates: Requirements 4.1, 4.2, 4.3, 4.4**

### Property 8: Sensitive Data Absence
*For any* configuration file in the public modules, the file should not contain hardcoded secrets, keys, credentials, or production-specific values
**Validates: Requirements 4.5, 5.2, 5.3**

### Property 9: Resource Creation Prevention
*For any* Terraform configuration in development mode, running terraform plan should show zero resources to be created
**Validates: Requirements 5.1**

### Property 10: Placeholder Usage Consistency
*For any* sensitive configuration parameter, the parameter should use template variables or placeholder patterns instead of actual values
**Validates: Requirements 5.4, 5.5**

## Error Handling

### Terraform Module Error Handling

**Input Validation Errors:**
- Invalid environment names should be rejected with clear error messages
- Invalid project names should be rejected with format requirements
- Missing required variables should be caught during validation

**Resource Configuration Errors:**
- Invalid resource configurations should be caught during terraform validate
- Circular dependencies between modules should be prevented through design
- Resource naming conflicts should be prevented through variable validation

### Docker Configuration Error Handling

**Build-Time Errors:**
- Invalid base image references should fail during docker build
- Missing environment variables should be documented with defaults
- Health check failures should be handled gracefully with retry logic

**Runtime Errors:**
- Container startup failures should be logged with clear error messages
- Database connection failures should be retried with exponential backoff
- Configuration errors should be validated before container startup

### Security Error Handling

**Sensitive Data Detection:**
- Automated scanning should detect and reject hardcoded secrets
- CI/CD pipelines should fail if sensitive data is detected
- Code review processes should flag potential security issues

**Access Control Errors:**
- Invalid IAM policies should be rejected during validation
- Overly permissive security groups should trigger warnings
- Missing encryption configurations should be caught during review

## Testing Strategy

### Dual Testing Approach

The testing strategy combines unit testing and property-based testing to ensure comprehensive coverage:

**Unit Tests:**
- Verify specific Terraform module configurations work correctly
- Test Docker container builds and basic functionality
- Validate security configurations meet requirements
- Test error handling for common failure scenarios

**Property-Based Tests:**
- Verify universal properties hold across all module configurations
- Test security properties across different input combinations
- Validate module independence across various usage patterns
- Test placeholder usage consistency across all configuration files

### Property-Based Testing Framework

**Testing Library:** We will use **Terratest** for Terraform module testing and **property-based testing patterns** within Go test framework.

**Test Configuration:**
- Each property-based test will run a minimum of 100 iterations
- Tests will generate random valid configurations to verify properties
- Each test will be tagged with comments referencing the design document properties

**Test Tagging Format:**
Each property-based test will include this exact comment format:
`**Feature: mautic-deployment, Property {number}: {property_text}**`

### Testing Implementation Requirements

**Property-Based Test Implementation:**
- Each correctness property must be implemented by a single property-based test
- Tests must be placed as close to implementation as possible for early error detection
- Property tests must validate universal behaviors across all valid inputs
- Test generators must create realistic, constrained input spaces

**Unit Test Implementation:**
- Unit tests complement property tests by covering specific examples and edge cases
- Tests must validate concrete scenarios and integration points
- Unit tests should focus on specific functionality rather than universal properties
- Tests must not use mocks for core functionality validation

### Test Categories

**Terraform Module Tests:**
- Module validation tests (terraform validate)
- Module planning tests (terraform plan with no resources created)
- Variable validation tests
- Output value tests
- Module independence tests

**Docker Configuration Tests:**
- Dockerfile syntax validation
- Base image verification
- Environment variable presence tests
- Health check configuration tests
- Security scanning tests

**Security Tests:**
- Sensitive data scanning tests
- IAM policy validation tests
- Security group rule validation tests
- Encryption configuration tests
- Placeholder usage validation tests

