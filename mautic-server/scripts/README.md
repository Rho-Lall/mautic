# Security Validation and Safeguards

This directory contains security validation scripts and safeguards for the Mautic public modules. These tools ensure that the public modules are secure, do not contain hardcoded secrets, and cannot accidentally create production resources.

## Scripts Overview

### 1. security-scan.sh
Comprehensive security scanning script that performs multiple security validations:

- **Hardcoded Secrets Detection**: Scans for AWS credentials, passwords, API keys, and other sensitive data
- **Placeholder Usage Validation**: Ensures proper use of variables instead of hardcoded values
- **Resource Creation Prevention**: Validates safeguards that prevent accidental resource creation
- **Terraform Security**: Validates Terraform modules for security best practices
- **Docker Security**: Validates Docker configurations for security issues
- **Development Safeguards**: Ensures development environment protections are in place

#### Usage:
```bash
# Run full security scan
./security-scan.sh

# Run specific checks
./security-scan.sh secrets      # Scan for hardcoded secrets only
./security-scan.sh terraform    # Validate Terraform security only
./security-scan.sh docker       # Validate Docker security only
```

### 2. validate-no-resources.sh
Specialized script that validates resource creation prevention:

- **Module Testing**: Tests each Terraform module to ensure no resources are created when `create_resources = false`
- **Example Validation**: Validates that example configurations use development settings
- **Variable Constraints**: Checks that variable validations prevent resource creation in dev environments
- **Hardcoded Values**: Scans for hardcoded production values that should be variables

#### Usage:
```bash
# Run full resource creation validation
./validate-no-resources.sh

# Run specific validations
./validate-no-resources.sh modules     # Test module resource prevention
./validate-no-resources.sh examples    # Validate example configurations
./validate-no-resources.sh variables   # Check variable constraints
```

## Security Safeguards Implementation

### 1. Resource Creation Prevention

Each Terraform module includes safeguards to prevent accidental resource creation:

```hcl
# Security Safeguards
variable "create_resources" {
  description = "Whether to create resources (set to false for development/testing)"
  type        = bool
  default     = false
  validation {
    condition     = var.environment == "dev" ? var.create_resources == false : true
    error_message = "Resource creation must be disabled in development environment."
  }
}

# All resources use conditional creation
resource "aws_vpc" "main" {
  count = var.create_resources ? 1 : 0
  # ... resource configuration
}
```

### 2. Environment Validation

Environment variables include validation to ensure proper usage:

```hcl
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### 3. Input Sanitization

All input variables include validation to prevent dangerous values:

```hcl
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
  validation {
    condition     = !can(regex("prod|production|live", var.project_name))
    error_message = "Project name must not contain production indicators for safety."
  }
}
```

## Security Patterns Detected

### Hardcoded Secrets Patterns
The security scanner detects these patterns:

- AWS Access Keys: `AKIA[0-9A-Z]{16}`
- Passwords: `password\s*=\s*['\"][^'\"]{8,}['\"]`
- API Keys: `api_key\s*=\s*['\"][^'\"]{8,}['\"]`
- Private Keys: `-----BEGIN PRIVATE KEY-----`
- Hardcoded ARNs: `arn:aws:iam::[0-9]{12}:`

### Forbidden Hardcoded Values
- Specific AWS account IDs (e.g., `123456789012`)
- Hardcoded resource names (e.g., `my-vpc`, `production`)
- Specific domain names (e.g., `example.com`)

## Development Environment Configuration

### Example Safe Configuration
```hcl
module "networking" {
  source = "./terraform/modules/networking"
  
  # Security safeguards
  create_resources = false  # Prevents resource creation
  environment      = "dev"  # Development environment
  project_name     = "test-project"
  
  # Safe development tags
  tags = {
    Environment = "development"
    Testing     = "true"
    Purpose     = "validation"
  }
}
```

### Validation Results
When properly configured, validation should show:
```
✅ Module networking: No resources will be created/modified/destroyed
✅ Example basic-setup: Uses development environment
✅ Example basic-setup: Resource creation disabled
✅ All security validations passed!
```

## Integration with CI/CD

### Pre-commit Hooks
Add to `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: local
    hooks:
      - id: security-scan
        name: Security Scan
        entry: ./public-modules/mautic-server/scripts/security-scan.sh
        language: script
        pass_filenames: false
        
      - id: validate-no-resources
        name: Validate No Resources
        entry: ./public-modules/mautic-server/scripts/validate-no-resources.sh
        language: script
        pass_filenames: false
```

### GitHub Actions
```yaml
name: Security Validation
on: [push, pull_request]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Security Scan
        run: ./public-modules/mautic-server/scripts/security-scan.sh
      - name: Validate No Resources
        run: ./public-modules/mautic-server/scripts/validate-no-resources.sh
```

## Troubleshooting

### Common Issues

1. **"Terraform validation failed"**
   - Ensure Terraform is installed and in PATH
   - Check module syntax with `terraform validate`

2. **"Resources would be created"**
   - Verify `create_resources = false` in module configuration
   - Check that `environment = "dev"` is set

3. **"Hardcoded secrets detected"**
   - Replace hardcoded values with variables
   - Use placeholder patterns like `CHANGEME` or `PLACEHOLDER`

4. **"Module missing variables.tf"**
   - Ensure each module has a `variables.tf` file
   - Include required security variables

### Security Scan Report
The security scan generates a detailed report at:
```
public-modules/mautic-server/security-scan-report.txt
```

This report includes:
- Summary of errors and warnings
- Detailed findings for each check
- Recommendations for fixes
- Next steps for remediation

## Best Practices

1. **Always run security scans** before committing changes
2. **Use development environment** for all testing and validation
3. **Never commit hardcoded secrets** or production values
4. **Validate resource creation prevention** for all modules
5. **Review security reports** and address all findings
6. **Use proper variable patterns** instead of hardcoded values
7. **Test with both enabled and disabled resource creation** to ensure modules work correctly

## Support

For questions or issues with security validation:
1. Check the troubleshooting section above
2. Review the security scan report for detailed findings
3. Ensure all prerequisites are met (Terraform, AWS CLI, etc.)
4. Verify module configurations follow the documented patterns