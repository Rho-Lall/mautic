# Secrets and Configuration Management Strategy

This document explains my approach to managing secrets, sensitive configuration, and resource names while keeping them out of version control.

## Table of Contents

- [Overview](#overview)
- [Secret Management Strategy](#secret-management-strategy)
- [Terraform Configuration File Types](#terraform-configuration-file-types)
- [Keeping Resource Names Out of Version Control](#keeping-resource-names-out-of-version-control)
- [File Structure and Patterns](#file-structure-and-patterns)
- [Security Implementation](#security-implementation)
- [Best Practices](#best-practices)
- [Examples](#examples)

## Overview

Our infrastructure uses a **hybrid approach** that balances security, usability, and compliance by:

1. **Never committing sensitive values** to version control
2. **Using AWS Secrets Manager** as the source of truth for sensitive configuration
3. **Leveraging environment variables** for dynamic values like AWS account IDs
4. **Providing template files** to show configuration structure without exposing real values
5. **Separating configuration types** into appropriate file formats

## Secret Management Strategy

### Three-Layer Security Model

We implement security through three distinct layers:

#### Layer 1: Shell Environment Variables
**Purpose**: Dynamic values that change between environments/accounts
**Location**: `deployment-credentials/*.env` files (git-ignored)
**Examples**:
```bash
export AWS_ACCOUNT_ID="123456789012"
export PROJECT_DOMAIN_NAME="yourdomain.com"
export PROJECT_DEV_DOMAIN="dev.yourdomain.com"
```

#### Layer 2: Terraform Variables
**Purpose**: Non-sensitive configuration values
**Location**: `terraform.tfvars` files
**Examples**:
```hcl
aws_region = "us-east-1"
project_name = "mautic-server"
lambda_memory_size = 256
```

#### Layer 3: AWS Secrets Manager
**Purpose**: Highly sensitive values (passwords, API keys, certificates)
**Location**: AWS Secrets Manager service
**Examples**:
```json
{
  "database_password": "secure-generated-password",
  "api_keys": {
    "webhook_secret": "random-32-char-string"
  },
  "custom_domain_name": "api.yourdomain.com",
  "certificate_arn": "arn:aws:acm:us-east-1:123456789012:certificate/..."
}
```

### Why This Approach?

✅ **Security**: Sensitive data never touches version control
✅ **Compliance**: Meets enterprise security requirements
✅ **Flexibility**: Easy to change values without code changes
✅ **Auditability**: AWS Secrets Manager provides access logs
✅ **Team Collaboration**: Templates show structure without exposing secrets

## Terraform Configuration File Types

Understanding Terraform's different file types is crucial for proper secret management:

### `.tfvars` Files (Terraform Variables)
**Purpose**: Set variable values (like `.env` files for Terraform)
**When Used**: `terraform plan -var-file=dev.tfvars`
**Security Level**: Non-sensitive values only

```hcl
# terraform.tfvars - Safe to commit
aws_region = "us-east-1"
project_name = "mautic-server"
environment = "dev"
lambda_timeout = 30
```

### `.hcl` Files (HashiCorp Configuration Language)
**Purpose**: Configuration settings, not variables
**When Used**: `terraform init -backend-config=backend.hcl`
**Security Level**: Uses environment variable substitution

```hcl
# backend.hcl - Uses env vars for dynamic values
bucket         = "terraform-state-${AWS_ACCOUNT_ID}-project-name"
key            = "project-name/production/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-locks"
```

### `.tf` Files (Terraform Configuration)
**Purpose**: Infrastructure definition
**When Used**: Always loaded automatically
**Security Level**: References variables and data sources

```hcl
# main.tf - References secure values
data "aws_secretsmanager_secret_version" "deployment_config" {
  secret_id = data.aws_secretsmanager_secret.deployment_config.id
}

locals {
  deployment_secrets = jsondecode(data.aws_secretsmanager_secret_version.deployment_config.secret_string)
  custom_domain_name = try(local.deployment_secrets.custom_domain_name, var.custom_domain_name)
}
```

### Variable Hierarchy (Highest to Lowest Priority)
1. **Command line**: `terraform apply -var="region=us-west-2"`
2. **`.tfvars` files**: `terraform.tfvars`, `dev.tfvars`
3. **Environment variables**: `TF_VAR_region=us-west-2`
4. **Default values** in `variables.tf`

## Keeping Resource Names Out of Version Control

### The Challenge
Resource names often contain:
- Domain names
- AWS account IDs
- Environment-specific identifiers
- Project-specific naming conventions

### Our Solution: Template Pattern + Environment Variables

#### What's Protected (Git-Ignored)
```gitignore
# Entire credentials directory
deployment-credentials/

# All environment files
*.env

# All credential files
*credentials*.json
*api-key*

# Terraform state (contains actual resource IDs)
*.tfstate
*.tfstate.*
.terraform/
```

#### What's Committed (Safe for Public)
```
# Template files showing structure
mautic-server/config/terraform/dev.tfvars.example
mautic-server/config/terraform/test.tfvars.example

# Infrastructure code (no hardcoded values)
serverless/terraform/production/main.tf
serverless/terraform/production/variables.tf

# Backend config (uses environment variables)
serverless/terraform/backend/backend.hcl
```

#### Resource Naming Strategy

**Instead of hardcoding**:
```hcl
# BAD - hardcoded values
resource "aws_s3_bucket" "state" {
  bucket = "terraform-state-123456789012-project-name"
}
```

**We use dynamic construction**:
```hcl
# GOOD - dynamic values
resource "aws_s3_bucket" "state" {
  bucket = "terraform-state-${var.aws_account_id}-${var.project_name}"
}
```

**With environment variable substitution**:
```hcl
# backend.hcl
bucket = "terraform-state-${AWS_ACCOUNT_ID}-project-name"
```

## File Structure and Patterns

### Directory Organization
```
project/
├── deployment-credentials/          # Git-ignored - real values
│   ├── project-environment.env     # Real AWS account, domains, resource names
│   ├── project-dev-secrets.json    # Real secret structure
│   └── api-environment.env         # Real API keys, endpoints
├── project-server/config/templates/ # Committed - examples only
│   ├── dev.tfvars.example         # Template with placeholders
│   ├── test.tfvars.example        # Template with placeholders
│   └── prod.tfvars.example        # Template with placeholders
└── serverless/terraform/
    ├── backend/
    │   └── backend.hcl            # Uses ${AWS_ACCOUNT_ID} substitution
    └── production/
        ├── main.tf                # Infrastructure code
        ├── terraform.tfvars       # Non-sensitive values only
        └── variables.tf           # Variable definitions
```

### Template File Pattern

**Real values** (git-ignored):
```bash
# deployment-credentials/project-environment.env
export AWS_ACCOUNT_ID="123456789012"
export PROJECT_DOMAIN_NAME="yourdomain.com"
export PROJECT_DEV_DOMAIN="app-dev.yourdomain.com"
```

**Template** (committed):
```hcl
# project-server/config/terraform/dev.tfvars.example
domain_name = "yourdomain.com"                    # Your registered domain
route53_zone_id = "Z1234567890ABC"                # Route 53 hosted zone ID
custom_domain_name = "app-dev.yourdomain.com"     # Development subdomain
```

## Security Implementation

### AWS Secrets Manager Integration

**Creating secrets**:
```bash
aws secretsmanager create-secret \
  --name "project-name/prod/deployment-config" \
  --description "Production deployment configuration" \
  --secret-string '{
    "custom_domain_name": "api.yourdomain.com",
    "certificate_arn": "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
    "database_password": "secure-generated-password"
  }'
```

**Accessing in Terraform**:
```hcl
data "aws_secretsmanager_secret" "deployment_config" {
  name = "project-name/prod/deployment-config"
}

data "aws_secretsmanager_secret_version" "deployment_config" {
  secret_id = data.aws_secretsmanager_secret.deployment_config.id
}

locals {
  deployment_secrets = jsondecode(data.aws_secretsmanager_secret_version.deployment_config.secret_string)
  custom_domain_name = try(local.deployment_secrets.custom_domain_name, var.custom_domain_name)
}
```

### Environment Variable Workflow

**1. Source environment variables**:
```bash
source deployment-credentials/mautic-environment.env
```

**2. Initialize Terraform with dynamic backend**:
```bash
terraform init -backend-config=backend.hcl
```

**3. Deploy with non-sensitive variables**:
```bash
terraform apply -var-file=terraform.tfvars
```

## Best Practices

### ✅ Do's

1. **Always use templates** for configuration examples
2. **Store sensitive values** in AWS Secrets Manager
3. **Use environment variables** for dynamic values like account IDs
4. **Document secret structure** in template files
5. **Validate .gitignore** regularly to ensure sensitive files are excluded
6. **Use descriptive variable names** that indicate their purpose
7. **Implement least-privilege access** to secrets

### ❌ Don'ts

1. **Never commit** real domain names, account IDs, or resource names
2. **Don't hardcode** sensitive values in Terraform files
3. **Avoid** storing secrets in environment variables long-term
4. **Don't share** credential files via email or chat
5. **Never** commit `.tfstate` files (contain actual resource IDs)
6. **Don't use** obvious placeholder values in production

### Security Checklist

- [ ] All sensitive files are in `.gitignore`
- [ ] Template files use placeholder values
- [ ] AWS Secrets Manager is configured for sensitive data
- [ ] Environment variables are sourced from ignored files
- [ ] Backend configuration uses variable substitution
- [ ] No hardcoded account IDs or domain names in committed code
- [ ] Secret access is logged and monitored

## Examples

### Complete Workflow Example

**1. Set up environment**:
```bash
# Source real values (git-ignored)
source deployment-credentials/project-environment.env

# Verify variables are set
echo $AWS_ACCOUNT_ID
echo $PROJECT_DOMAIN_NAME
```

**2. Initialize Terraform**:
```bash
cd serverless/terraform/production

# Backend config uses ${AWS_ACCOUNT_ID} from environment
terraform init -backend-config=../backend/backend.hcl
```

**3. Plan deployment**:
```bash
# terraform.tfvars contains only non-sensitive values
# Sensitive values come from AWS Secrets Manager
terraform plan
```

**4. Apply changes**:
```bash
terraform apply
```

### Secret Structure Example

**AWS Secrets Manager secret** (`project-name/prod/deployment-config`):
```json
{
  "custom_domain_name": "api.yourdomain.com",
  "certificate_arn": "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
  "route53_zone_id": "Z1234567890ABC",
  "cors_allowed_origins": [
    "https://yourdomain.com",
    "https://www.yourdomain.com"
  ],
  "sender_emails": ["noreply@yourdomain.com"],
  "database_password": "randomly-generated-secure-password",
  "api_keys": {
    "webhook_secret": "32-character-random-string"
  }
}
```

**Terraform usage**:
```hcl
locals {
  deployment_secrets = jsondecode(data.aws_secretsmanager_secret_version.deployment_config.secret_string)
  
  # Use secrets with fallback to variables
  custom_domain_name = try(local.deployment_secrets.custom_domain_name, var.custom_domain_name)
  cors_allowed_origins = try(local.deployment_secrets.cors_allowed_origins, var.cors_allowed_origins)
}

resource "aws_route53_record" "api_domain" {
  zone_id = local.deployment_secrets.route53_zone_id
  name    = local.custom_domain_name
  # ... rest of configuration
}
```

This approach ensures that sensitive configuration never appears in version control while maintaining the flexibility and transparency needed for effective infrastructure management.