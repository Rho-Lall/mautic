# Private Repository Setup Guide

This guide walks you through setting up a private repository for production deployment using the public serverless lead capture modules as a Git submodule.

## Overview

The serverless lead capture system uses a two-repository approach:

- **Public Repository**: Contains source code, reusable Terraform modules, and documentation
- **Private Repository**: Contains environment-specific configurations, secrets, and deployment workflows

This guide helps you set up the private repository that references the public modules.

## Prerequisites

Before starting this guide, ensure you have completed:

1. ✅ **AWS Account Setup** (Tasks 0.1-0.3 from the implementation plan)
   - AWS CLI configured with credentials
   - Terraform backend infrastructure (S3 bucket and DynamoDB table)
   - Domain and SSL certificate setup (optional)

2. ✅ **Public Repository** 
   - Public repository committed and pushed to GitHub
   - All Terraform modules and documentation completed

## Step 1: Create Private Repository

### 1.1 Create GitHub Repository

1. **Go to GitHub** and create a new repository
2. **Repository Settings**:
   - Name: `serverless-lead-capture-prod` (or your preferred name)
   - Visibility: **Private** ⚠️
   - Initialize: **Do not** initialize with README, .gitignore, or license
3. **Create Repository**

### 1.2 Clone Private Repository

```bash
# Clone your new private repository
git clone https://github.com/yourusername/serverless-lead-capture-prod.git
cd serverless-lead-capture-prod

# Verify you're in the private repo
git remote -v
# Should show your private repo URL
```

## Step 2: Add Public Repository as Submodule

### 2.1 Add Submodule

```bash
# Add the public repository as a submodule
git submodule add https://github.com/yourusername/serverless-lead-capture.git public-modules

# This creates:
# - public-modules/ directory with the public repo content
# - .gitmodules file with submodule configuration
```

### 2.2 Verify Submodule Setup

```bash
# Check submodule status
git submodule status

# Should show something like:
# +abc1234 public-modules (heads/main)

# Verify directory structure
ls -la
# Should show:
# drwxr-xr-x  public-modules/
# -rw-r--r--  .gitmodules
```

### 2.3 Commit Submodule

```bash
# Add and commit the submodule
git add .gitmodules public-modules
git commit -m "Add public serverless-lead-capture modules as submodule"
git push origin main
```

## Step 3: Create Private Repository Structure

### 3.1 Create Directory Structure

```bash
# Create directory structure for private repository
mkdir -p terraform/environments/{dev,prod}
mkdir -p terraform/shared
mkdir -p .github/workflows
mkdir -p config
mkdir -p scripts
mkdir -p docs

# Create initial files
touch terraform/environments/dev/{main.tf,variables.tf,outputs.tf,terraform.tfvars.example}
touch terraform/environments/prod/{main.tf,variables.tf,outputs.tf,terraform.tfvars.example}
touch terraform/shared/{backend.tf,providers.tf}
touch .github/workflows/{deploy-dev.yml,deploy-prod.yml}
touch config/{dev.tfvars.example,prod.tfvars.example}
touch scripts/{setup-aws-profile.sh,encrypt-secrets.sh}
touch docs/{deployment.md,troubleshooting.md}
touch README.md
```

### 3.2 Verify Structure

```bash
# Check the complete structure
tree -a
# Should show:
# .
# ├── .git/
# ├── .github/
# │   └── workflows/
# │       ├── deploy-dev.yml
# │       └── deploy-prod.yml
# ├── .gitmodules
# ├── README.md
# ├── config/
# │   ├── dev.tfvars.example
# │   └── prod.tfvars.example
# ├── docs/
# │   ├── deployment.md
# │   └── troubleshooting.md
# ├── public-modules/           # Git submodule
# │   └── [public repo content]
# ├── scripts/
# │   ├── encrypt-secrets.sh
# │   └── setup-aws-profile.sh
# └── terraform/
#     ├── environments/
#     │   ├── dev/
#     │   └── prod/
#     └── shared/
```

## Step 4: Configure Terraform Backend

### 4.1 Create Shared Backend Configuration

```bash
# Create backend configuration
cat > terraform/shared/backend.tf << 'EOF'
terraform {
  backend "s3" {
    # These values will be provided via backend config files
    # or command line arguments during terraform init
  }
}
EOF
```

### 4.2 Create Backend Config Files

```bash
# Development backend config
cat > config/backend-dev.hcl << 'EOF'
bucket         = "your-terraform-state-bucket"
key            = "lead-capture/dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-locks"
encrypt        = true
EOF

# Production backend config
cat > config/backend-prod.hcl << 'EOF'
bucket         = "your-terraform-state-bucket"
key            = "lead-capture/prod/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-locks"
encrypt        = true
EOF
```

## Step 5: Create Development Environment Configuration

### 5.1 Development Main Configuration

```bash
cat > terraform/environments/dev/main.tf << 'EOF'
# Development Environment Configuration
# References public modules via Git submodule

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Include shared backend configuration
terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "lead-capture"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

locals {
  environment = "dev"
  common_tags = {
    Project     = "lead-capture"
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

# DynamoDB Table
module "dynamodb" {
  source = "../../../public-modules/serverless/lead-capture/terraform/modules/dynamodb"

  table_name   = "lead-capture-leads-${local.environment}"
  billing_mode = "PAY_PER_REQUEST"
  
  enable_encryption             = true
  enable_point_in_time_recovery = true
  enable_monitoring            = true
  
  tags = local.common_tags
}

# Lambda Functions
module "lambda" {
  source = "../../../public-modules/serverless/lead-capture/terraform/modules/lambda"

  function_name_prefix = "lead-capture-${local.environment}"
  runtime              = "nodejs18.x"
  timeout              = 30
  memory_size          = 256

  submit_lambda_zip_path = var.submit_lambda_zip_path
  get_lambda_zip_path    = var.get_lambda_zip_path

  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn

  cors_allow_origin = var.cors_allow_origin
  enable_ses        = var.enable_email_notifications

  tags = local.common_tags
}

# API Gateway
module "api_gateway" {
  source = "../../../public-modules/serverless/lead-capture/terraform/modules/api-gateway"

  api_name        = "lead-capture-api-${local.environment}"
  api_description = "Lead capture API for ${local.environment}"
  stage_name      = local.environment

  submit_lambda_invoke_arn    = module.lambda.submit_lambda_invoke_arn
  get_lambda_invoke_arn       = module.lambda.get_lambda_invoke_arn
  submit_lambda_function_name = module.lambda.submit_lambda_function_name
  get_lambda_function_name    = module.lambda.get_lambda_function_name

  cors_allow_origin = var.cors_allow_origin
  enable_api_key    = true

  tags = local.common_tags
}

# Optional SES
module "ses" {
  count  = var.enable_email_notifications ? 1 : 0
  source = "../../../public-modules/serverless/lead-capture/terraform/modules/ses"

  sender_emails          = var.sender_emails
  configuration_set_name = "lead-capture-${local.environment}"
  
  enable_monitoring         = true
  enable_cloudwatch_logging = true
  
  tags = local.common_tags
}
EOF
```

### 5.2 Development Variables

```bash
cat > terraform/environments/dev/variables.tf << 'EOF'
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "submit_lambda_zip_path" {
  description = "Path to submit Lambda ZIP file"
  type        = string
}

variable "get_lambda_zip_path" {
  description = "Path to get Lambda ZIP file"
  type        = string
}

variable "cors_allow_origin" {
  description = "CORS allowed origin"
  type        = string
  default     = "*"
}

variable "enable_email_notifications" {
  description = "Enable SES email notifications"
  type        = bool
  default     = false
}

variable "sender_emails" {
  description = "List of verified sender emails"
  type        = list(string)
  default     = []
}
EOF
```

### 5.3 Development Outputs

```bash
cat > terraform/environments/dev/outputs.tf << 'EOF'
output "api_gateway_url" {
  description = "API Gateway URL"
  value       = module.api_gateway.api_gateway_url
}

output "api_key_value" {
  description = "API key for authentication"
  value       = module.api_gateway.api_key_value
  sensitive   = true
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "lambda_functions" {
  description = "Lambda function information"
  value = {
    submit_lead = module.lambda.submit_lambda_function_name
    get_leads   = module.lambda.get_lambda_function_name
  }
}
EOF
```

### 5.4 Development Variables Example

```bash
cat > terraform/environments/dev/terraform.tfvars.example << 'EOF'
# Development Environment Configuration
# Copy this file to terraform.tfvars and customize

aws_region = "us-east-1"

# Lambda deployment packages (build these first)
submit_lambda_zip_path = "../../../dist/submit-lead.zip"
get_lambda_zip_path    = "../../../dist/get-leads.zip"

# CORS configuration (use * for development)
cors_allow_origin = "*"

# Email notifications (optional for dev)
enable_email_notifications = false
sender_emails              = []

# Add any additional development-specific variables here
EOF
```

## Step 6: Create Production Environment Configuration

### 6.1 Production Configuration

```bash
# Copy dev configuration as starting point for production
cp -r terraform/environments/dev/* terraform/environments/prod/

# Update production main.tf for production-specific settings
cat > terraform/environments/prod/main.tf << 'EOF'
# Production Environment Configuration
# References public modules via Git submodule

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "lead-capture"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

locals {
  environment = "prod"
  common_tags = {
    Project     = "lead-capture"
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

# Use the production-ready example from public modules
module "production_stack" {
  source = "../../../public-modules/serverless/lead-capture/terraform/examples/production-setup"

  aws_region = var.aws_region

  submit_lambda_zip_path = var.submit_lambda_zip_path
  get_lambda_zip_path    = var.get_lambda_zip_path

  cors_allow_origin  = var.cors_allow_origin
  custom_domain_name = var.custom_domain_name
  certificate_arn    = var.certificate_arn

  enable_email_notifications = var.enable_email_notifications
  sender_emails             = var.sender_emails
  ses_domain_name          = var.ses_domain_name

  alert_email_addresses = var.alert_email_addresses
}
EOF
```

### 6.2 Production Variables Example

```bash
cat > terraform/environments/prod/terraform.tfvars.example << 'EOF'
# Production Environment Configuration
# Copy this file to terraform.tfvars and customize with your values

aws_region = "us-east-1"

# Lambda deployment packages
submit_lambda_zip_path = "../../../dist/submit-lead.zip"
get_lambda_zip_path    = "../../../dist/get-leads.zip"

# CORS configuration (use your actual domain)
cors_allow_origin = "https://yourdomain.com"

# Custom domain configuration
custom_domain_name = "api.yourdomain.com"
certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/your-cert-id"

# Email notifications
enable_email_notifications = true
sender_emails             = ["noreply@yourdomain.com"]
ses_domain_name          = "yourdomain.com"

# Monitoring
alert_email_addresses = ["admin@yourdomain.com"]
EOF
```

## Step 7: Create Initial README

```bash
cat > README.md << 'EOF'
# Serverless Lead Capture - Production Deployment

This private repository contains production deployment configurations for the serverless lead capture system.

## Repository Structure

```
├── public-modules/           # Git submodule (public repository)
├── terraform/
│   ├── environments/
│   │   ├── dev/             # Development environment
│   │   └── prod/            # Production environment
│   └── shared/              # Shared configurations
├── config/                  # Backend and variable configurations
├── .github/workflows/       # CI/CD workflows
└── scripts/                 # Deployment scripts
```

## Quick Start

### Prerequisites
- AWS CLI configured
- Terraform >= 1.0 installed
- Lambda deployment packages built

### Development Deployment

1. **Initialize Terraform:**
   ```bash
   cd terraform/environments/dev
   terraform init -backend-config=../../../config/backend-dev.hcl
   ```

2. **Configure Variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Deploy:**
   ```bash
   terraform plan
   terraform apply
   ```

### Production Deployment

1. **Initialize Terraform:**
   ```bash
   cd terraform/environments/prod
   terraform init -backend-config=../../../config/backend-prod.hcl
   ```

2. **Configure Variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with production values
   ```

3. **Deploy:**
   ```bash
   terraform plan
   terraform apply
   ```

## Updating Public Modules

To update the public modules to the latest version:

```bash
cd public-modules
git pull origin main
cd ..
git add public-modules
git commit -m "Update public modules to latest version"
git push
```

## Documentation

- [Public Repository Documentation](./public-modules/README.md)
- [Terraform Modules Documentation](./public-modules/serverless/lead-capture/terraform/README.md)
- [Deployment Guide](./docs/deployment.md)
- [Troubleshooting](./docs/troubleshooting.md)
EOF
```

## Step 8: Commit Initial Structure

```bash
# Add all files
git add .

# Commit the initial structure
git commit -m "Initial private repository structure with public modules submodule

- Add Git submodule for public serverless-lead-capture repository
- Create Terraform environment configurations for dev and prod
- Add backend configuration files
- Create initial documentation and examples"

# Push to remote
git push origin main
```

## Step 9: Working with the Private Repository

### 9.1 Cloning with Submodules

When others clone your private repository:

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/yourusername/serverless-lead-capture-prod.git

# Or if already cloned without submodules:
git submodule update --init --recursive
```

### 9.2 Updating Submodules

```bash
# Update to latest public repository changes
cd public-modules
git pull origin main
cd ..
git add public-modules
git commit -m "Update public modules to latest version"

# Pin to specific version/tag
cd public-modules
git checkout v1.0.0  # or specific commit
cd ..
git add public-modules
git commit -m "Pin public modules to v1.0.0"
```

### 9.3 Building Lambda Packages

Before deploying, build your Lambda packages:

```bash
# Build Lambda functions from public modules
cd public-modules/serverless/lead-capture/src/lambda
npm install --production

# Create deployment packages
mkdir -p ../../../../dist
zip -r ../../../../dist/submit-lead.zip handlers/submit-lead.js utils/ node_modules/
zip -r ../../../../dist/get-leads.zip handlers/get-leads.js utils/ node_modules/

cd ../../../../
```

## Next Steps

1. **Customize Configurations**: Edit the `terraform.tfvars` files for your environments
2. **Set up CI/CD**: Configure GitHub Actions workflows for automated deployment
3. **Add Secrets**: Use GitHub Secrets for sensitive configuration values
4. **Deploy Development**: Test deployment in development environment first
5. **Deploy Production**: Deploy to production with proper review process

## Security Notes

- ⚠️ **Never commit sensitive values** like API keys or passwords to Git
- ✅ **Use GitHub Secrets** for sensitive environment variables in CI/CD
- ✅ **Use Terraform backend encryption** for state files
- ✅ **Restrict repository access** to authorized team members only

## Support

- [Public Repository Issues](https://github.com/yourusername/serverless-lead-capture/issues)
- [Terraform Documentation](./public-modules/serverless/lead-capture/terraform/README.md)
- [AWS Documentation](https://docs.aws.amazon.com/)