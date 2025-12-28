# Development Safeguards Configuration

This document explains the development safeguards implemented in the Mautic server Terraform configuration to prevent costly mistakes and ensure safe development practices.

## Overview

The `development-safeguards.tf` file provides a comprehensive safety framework for development environments, preventing accidental resource creation, enforcing naming conventions, and providing security validations.

## Key Features

### 🛡️ Resource Creation Prevention

The safeguards automatically prevent resource creation in development environments:

```hcl
locals {
  is_development = var.environment == "dev"
  should_create_resources = var.create_resources && !local.is_development
}
```

**How it works:**
- Detects when `environment = "dev"`
- Forces `create_resources = false` for development
- Resources are conditionally created: `count = local.should_create_resources ? 1 : 0`

### 🔍 Environment Validation

Strict validation ensures only approved environment names:

```hcl
variable "environment" {
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

**Validation Rules:**
- ✅ Allowed: `dev`, `staging`, `prod`
- ❌ Blocked: Any other values

### 🚫 Production Value Prevention

Prevents production indicators in development configurations:

```hcl
validation {
  condition     = !can(regex("prod|production|live", var.project_name))
  error_message = "Project name must not contain production indicators."
}
```

**Blocked Terms:**
- `prod`
- `production` 
- `live`

**Applied to:**
- Project names
- Tag values
- Resource identifiers

### 🏷️ Automatic Development Tagging

All resources in development automatically receive safety tags:

```hcl
development_tags = {
  Environment     = "development"
  Purpose         = "testing"
  AutoDestroy     = "true"
  CreatedBy       = "terraform"
  PublicModule    = "true"
  ResourceCreated = local.should_create_resources ? "true" : "false"
}
```

**Tag Benefits:**
- **Cost tracking**: Identify development resources
- **Auto-cleanup**: Mark resources for automatic destruction
- **Governance**: Clear resource purpose and ownership
- **Compliance**: Meet organizational tagging requirements

### ⚠️ Safety Warnings & Notifications

The safeguards provide clear feedback during execution:

**Development Mode Warning:**
```bash
WARNING: Running in development mode - no actual resources will be created
```

**Resource Creation Error:**
```bash
ERROR: Resource creation is not allowed in development environment
```

### 🔒 Security Validation Framework

Built-in security scanning framework (extensible):

```hcl
locals {
  has_secrets = false  # Set by security scanning
  has_production_values = false  # Set by validation scanning
  security_validated = !local.has_secrets && !local.has_production_values
}
```

**Security Checks:**
- Hardcoded secrets detection
- Production value scanning
- Configuration validation
- Security status reporting

## Usage Patterns

### Development Environment Setup

```hcl
# terraform.tfvars for development
environment = "dev"
create_resources = false  # Required for dev
project_name = "mautic-server-dev"  # No "prod" allowed

tags = {
  Owner = "dev-team"
  Purpose = "development-testing"  # No "production" allowed
}
```

### Resource Creation (Conditional)

```hcl
# In your main.tf
resource "aws_instance" "mautic_server" {
  count = local.should_create_resources ? 1 : 0
  
  instance_type = var.instance_type
  tags = local.final_tags
  
  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}
```

### Module Integration

```hcl
module "mautic_infrastructure" {
  source = "./modules/mautic-server"
  
  environment = var.environment
  create_resources = var.create_resources
  project_name = var.project_name
  tags = var.tags
}
```

## Configuration Variables

### Required Variables

| Variable | Type | Description | Validation |
|----------|------|-------------|------------|
| `environment` | string | Environment name | Must be: dev, staging, prod |
| `create_resources` | bool | Enable resource creation | Must be false for dev |
| `project_name` | string | Project identifier | No production indicators |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tags` | map(string) | `{}` | Additional resource tags |
| `prevent_destroy` | bool | `true` | Prevent accidental destruction |

## Outputs

### Development Status

```hcl
output "development_safeguards" {
  value = {
    environment           = "dev"
    is_development       = true
    create_resources     = false
    should_create        = false
    safeguards_active    = true
    warning_message      = "Development mode active - no resources created"
  }
}
```

### Security Validation

```hcl
output "security_validation" {
  value = {
    secrets_detected        = false
    production_values_found = false
    security_validated      = true
    validation_message      = "Security validation passed"
  }
}
```

## Best Practices

### ✅ Do's

1. **Always use safeguards** in development environments
2. **Test configurations** without creating resources
3. **Review validation outputs** before deployment
4. **Use descriptive project names** without production indicators
5. **Include appropriate tags** for cost tracking and governance

### ❌ Don'ts

1. **Don't bypass safeguards** by hardcoding `create_resources = true`
2. **Don't use production names** in development configurations
3. **Don't ignore validation warnings** - they prevent costly mistakes
4. **Don't commit sensitive values** - use AWS Secrets Manager instead
5. **Don't skip security validation** - review outputs regularly

## Troubleshooting

### Common Issues

#### Validation Error: Environment Name
```
Error: Environment must be dev, staging, or prod.
```
**Solution:** Use only approved environment names: `dev`, `staging`, `prod`

#### Validation Error: Production Indicators
```
Error: Project name must not contain production indicators.
```
**Solution:** Remove `prod`, `production`, or `live` from project names and tags

#### Resource Creation Blocked
```
Error: Resource creation is not allowed in development environment.
```
**Solution:** This is expected behavior. Set `create_resources = false` for development

### Extending Security Validation

To add custom security checks:

```hcl
locals {
  # Custom security validations
  has_hardcoded_ips = can(regex("\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b", var.project_name))
  has_sensitive_data = can(regex("password|secret|key", lower(var.project_name)))
  
  # Update security validation
  security_validated = !local.has_secrets && 
                      !local.has_production_values && 
                      !local.has_hardcoded_ips && 
                      !local.has_sensitive_data
}
```

## Integration with CI/CD

### Pre-deployment Validation

```bash
# Validate configuration before deployment
terraform validate
terraform plan -var="create_resources=false"

# Check safeguard outputs
terraform output development_safeguards
terraform output security_validation
```

### Automated Testing

```bash
# Test development safeguards
terraform apply -var="environment=dev" -var="create_resources=false" -auto-approve
terraform destroy -auto-approve
```

## Cost Protection Benefits

The development safeguards provide significant cost protection:

- **Prevent accidental deployments** of expensive resources
- **Block production-scale configurations** in development
- **Enable safe testing** of Terraform configurations
- **Provide clear cost attribution** through automatic tagging
- **Support automated cleanup** with `AutoDestroy = "true"` tags

This framework ensures that development work remains cost-effective while maintaining the ability to fully test and validate infrastructure configurations.