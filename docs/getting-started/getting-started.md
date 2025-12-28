# Getting Started

Welcome to the Mautic Marketing Automation Suite! This guide provides an overview of the setup process and links to detailed installation guides.

## Prerequisites

Before you begin, ensure you have:

- AWS account with appropriate permissions
- Basic understanding of AWS services
- Terminal/command line access
- Git installed

## Installation Guides

Step-by-step guides for setting up the required infrastructure:

### 1. [AWS CLI Setup](installation-guides/aws-cli-setup.md)
Configure AWS CLI and create necessary IAM users with appropriate permissions.

**What you'll learn:**
- Creating an AWS account
- Installing AWS CLI v2
- Setting up IAM users for development
- Configuring AWS credentials

### 2. [Terraform Backend Setup](installation-guides/terraform-backend-setup.md)
Set up S3 and DynamoDB for Terraform state management.

**What you'll learn:**
- Creating S3 buckets for state storage
- Setting up DynamoDB for state locking
- Configuring IAM policies for Terraform
- Backend configuration best practices

### 3. [Domain Setup](installation-guides/domain-setup.md) (Optional)
Configure custom domains for production deployment.

**What you'll learn:**
- Route 53 domain registration
- SSL certificate setup with ACM
- DNS configuration
- CORS considerations for custom domains

### 4. [Deployment Guide](installation-guides/deployment.md)
Deploy the infrastructure using Terraform and configure the applications.

**What you'll learn:**
- Private repository setup
- Multi-environment deployment strategy
- Terraform module usage
- Production deployment best practices

## Choose Your Product

### Serverless Lead Capture
Perfect for static websites and GitHub Pages.

- Embeddable forms
- AWS serverless backend
- Real-time lead capture

[Serverless Guide](../products/serverless/overview.md){ .md-button .md-button--primary }

### Mautic Server
Full-featured marketing automation platform.

- Self-hosted Mautic
- Docker-based deployment
- Advanced automation workflows

[Mautic Server Guide](../products/mautic-server/overview.md){ .md-button }

## Quick Start Path

For those who want to explore the implementation:

1. **[Review Architecture](../architecture.md)** - Understand the system design
2. **[Explore Installation Guides](#installation-guides)** - See the setup process
3. **[Check Product Documentation](#choose-your-product)** - Deep dive into components
4. **Review Terraform Modules** - Examine infrastructure code in the [Serverless](../products/serverless/overview.md#terraform-modules) and [Mautic Server](../products/mautic-server/overview.md#terraform-modules) docs

## Need Help?

- Check the [Architecture documentation](../architecture.md)
- Review installation guide troubleshooting sections
- Examine the Terraform module documentation


- **[Installation Guides](installation-guides/aws-cli-setup.md)** - AWS setup and Terraform backend configuration

