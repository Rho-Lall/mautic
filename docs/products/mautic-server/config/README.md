# Application Server Configuration Management

This directory contains configuration templates and documentation for managing application server deployments (such as Mautic or other open source projects) across different environments.

## Table of Contents

- [Configuration Files](#configuration-files)
  - [Environment Configuration Templates](#environment-configuration-templates)
  - [Docker Configuration Templates](#docker-configuration-templates)
  - [Usage](#usage)
- [AWS Setup and Prerequisites](#aws-setup-and-prerequisites)
  - [AWS Profile Setup](#aws-profile-setup)
  - [Domain Setup with Route 53](#domain-setup-with-route-53)
  - [SES Email Service Setup](#ses-email-service-setup)
- [AWS Secrets Manager Integration](#aws-secrets-manager-integration)
  - [Secret Structure](#secret-structure)
  - [Required Secret Keys](#required-secret-keys)
  - [Optional Integration Keys](#optional-integration-keys)
- [Secret Management Commands](#secret-management-commands)
  - [Create Secrets for All Environments](#create-secrets-for-all-environments)
  - [List All Secrets](#list-all-secrets)
  - [Validate Secret Structure](#validate-secret-structure)
  - [Rotate Passwords](#rotate-passwords)
- [Security Best Practices](#security-best-practices)
  - [Secret Management](#secret-management)
  - [Configuration Files](#configuration-files-1)
  - [SES Configuration](#ses-configuration)
- [Secret Rotation Procedures](#secret-rotation-procedures)
- [Troubleshooting](#troubleshooting)
  - [Common Issues](#common-issues)
  - [Getting Help](#getting-help)
- [Environment-Specific Notes](#environment-specific-notes)
  - [Development Environment](#development-environment)
  - [Test Environment](#test-environment)
  - [Production Environment](#production-environment)

## Configuration Files

### Secrets
- `mautic-{env}-secrets.json` - Environment-specific AWS Secrets Manager templates (e.g., `mautic-dev-secrets.json`, `mautic-test-secrets.json`, `mautic-secrets.json`)

This should be added to your git ignore and not committed anywhere.

### Environment Configuration Templates

- `templates/dev.tfvars.example` - Development environment configuration template
- `templates/test.tfvars.example` - Test environment configuration template  
- `templates/prod.tfvars.example` - Production environment configuration template
- `templates/development-safeguards.tf` - Development environment safety configurations

### Docker Configuration Templates

- `templates/apache.conf` - Apache web server configuration optimized for PHP applications
- `templates/php.ini` - PHP configuration with performance and security settings for web applications

### Usage

1. Copy the appropriate `.tfvars.example` file to create your environment configuration
2. Edit the configuration file with your specific values
3. Manage secrets with AWS Secrets Manager

## AWS Setup and Prerequisites

Before deploying an app or open source project, like Mautic, you need to set up several AWS services and configurations. 

Follow these guides in order:

### AWS Profile Setup

**📖 See: [`aws-profile-setup.md`](aws-profile-setup.md)** *(Private repository only)*

Set up AWS credentials and IAM roles with the necessary permissions for application deployment. This guide covers:
- Creating IAM roles with appropriate permissions
- Configuring AWS CLI profiles
- Testing access to required AWS services (Route 53, SES, ECS, RDS, etc.)

### Domain Setup with Route 53

**📖 See: [`domain-setup.md`](domain-setup.md)**

Configure your domain with AWS Route 53 for optimal integration with AWS services. This comprehensive guide covers:
- Domain registration with Route 53 (recommended for AWS compliance)
- Hosted zone configuration and DNS management
- Subdomain planning for different environments
- Benefits of Route 53 for enterprise applications

### SES Email Service Setup

**📖 See: [`ses-setup-guide.md`](ses-setup-guide.md)**

Set up AWS Simple Email Service (SES) for your application's email infrastructure. This guide includes:
- Domain verification and DKIM configuration
- Environment-specific SES configurations
- SMTP credentials management
- Email deliverability best practices
- Monitoring and troubleshooting email issues

## AWS Secrets Manager Integration

### Secret Structure

The `deployment-credentials/mautic-{env}-secrets.json` files provide the exact JSON structure that your AWS Secrets Manager secrets should follow for each environment. This template file:

- Shows all required and optional secret keys
- Provides placeholder values that you replace with real values
- Serves as documentation for what secrets your application needs
- Can be used as a reference when creating secrets manually or via scripts

Each environment requires a secret in AWS Secrets Manager with the following naming convention:
- Development: `your-app-dev-secrets`
- Test: `your-app-test-secrets`
- Production: `your-app-prod-secrets`

### Required Secret Keys

The following keys are required in each secret:

#### Database Configuration
- `database_password` - Secure password for RDS database

#### Application Configuration
- `app_secret_key` - 32-character secret key for application encryption

#### Admin Credentials
- `admin_credentials.admin_email` - Initial admin user email
- `admin_credentials.admin_password` - Initial admin user password
- `admin_credentials.admin_firstname` - Admin user first name
- `admin_credentials.admin_lastname` - Admin user last name

#### Email Configuration (SES)
- `email_configuration.smtp_host` - SES SMTP endpoint
- `email_configuration.smtp_port` - SMTP port (usually 587)
- `email_configuration.smtp_username` - SES SMTP username
- `email_configuration.smtp_password` - SES SMTP password
- `email_configuration.from_email` - Default sender email address
- `email_configuration.from_name` - Default sender name (e.g., "Your Company App")

#### Domain Configuration
- `domain_configuration.domain_name` - Primary domain name
- `domain_configuration.route53_zone_id` - Route 53 hosted zone ID
- `domain_configuration.ssl_certificate_arn` - ACM certificate ARN

#### SES Configuration
- `ses_configuration.configuration_set_name` - SES configuration set name
- `ses_configuration.reputation_tracking_enabled` - Enable reputation tracking
- `ses_configuration.delivery_options_tls_policy` - TLS policy for delivery

#### API Keys
- `api_keys.app_api_key` - Application API access key
- `api_keys.webhook_secret` - Webhook validation secret

#### Environment-Specific Settings
- `environment_specific.trusted_hosts` - Comma-separated list of trusted hosts for the application
- `environment_specific.cors_allowed_origins` - CORS allowed origins for API access
- `environment_specific.session_timeout` - Session timeout in seconds
- `environment_specific.max_upload_size` - Maximum file upload size

### Optional Integration Keys

These keys are optional and can be left empty if not using the integrations:

- `external_integrations.google_analytics_id` - Google Analytics tracking ID
- `external_integrations.facebook_pixel_id` - Facebook Pixel ID
- `external_integrations.recaptcha_site_key` - reCAPTCHA site key
- `external_integrations.recaptcha_secret_key` - reCAPTCHA secret key

## Secret Management Commands

Use the secrets management script to create and manage secrets:

### Create Secrets for All Environments

```bash
# Create development secret
./scripts/manage-secrets.sh create dev yourdomain.com

# Create test secret
./scripts/manage-secrets.sh create test yourdomain.com

# Create production secret
./scripts/manage-secrets.sh create prod yourdomain.com
```

### List All Secrets

```bash
./scripts/manage-secrets.sh list
```

### Validate Secret Structure

```bash
# Validate development secret
./scripts/manage-secrets.sh validate dev

# Validate production secret
./scripts/manage-secrets.sh validate prod
```

### Rotate Passwords

```bash
# Rotate passwords in development secret
./scripts/manage-secrets.sh rotate dev

# Rotate passwords in production secret
./scripts/manage-secrets.sh rotate prod
```

## Security Best Practices

### Secret Management

1. **Never commit secrets to version control** - All sensitive values should be stored in AWS Secrets Manager
2. **Use strong passwords** - The management script generates cryptographically secure passwords
3. **Rotate secrets regularly** - Use the rotate command to update passwords periodically
4. **Limit access** - Use IAM policies to restrict access to secrets
5. **Monitor access** - Enable CloudTrail logging for secret access

### Configuration Files

1. **Use templates** - Always start with the provided `.example` files
2. **Validate syntax** - Use `terraform validate` to check configuration syntax
3. **Environment isolation** - Keep separate configuration files for each environment
4. **Document changes** - Comment any custom modifications to configuration files

### SES Configuration

1. **Domain verification** - Ensure domains are verified in SES before deployment
2. **DKIM setup** - Configure DKIM for email authentication
3. **Bounce handling** - Set up bounce and complaint handling
4. **Reputation monitoring** - Monitor sending reputation and deliverability

## Secret Rotation Procedures

**📖 See: [`secret-rotation-procedures.md`](secret-rotation-procedures.md)**

Regular secret rotation is critical for security. This comprehensive guide covers:

- **Rotation Schedule**: Recommended frequencies for different types of credentials
- **Automated Rotation**: Using scripts for password generation and updates
- **Manual Rotation**: Step-by-step procedures for specific credential types
- **Post-Rotation Procedures**: Validation, service restarts, and monitoring
- **Troubleshooting**: Common issues and recovery procedures
- **Security Considerations**: Access control, audit trails, and best practices

Key rotation frequencies:
- Database passwords: Every 90 days
- Admin passwords: Every 60 days
- API keys: Every 90 days
- SES SMTP credentials: Every 180 days

## Troubleshooting

### Common Issues

### BIOLER PLATE ISSUES (consider inclusion based on need)

#### Secret Not Found
```
Error: Secret not found: your-app-dev-secrets
```
**Solution:** Create the secret using the management script:
```bash
./scripts/manage-secrets.sh create dev yourdomain.com
```

#### Invalid Secret Structure
```
Error: Required secret key 'database_password' not found
```
**Solution:** Validate and update the secret structure:
```bash
./scripts/manage-secrets.sh validate dev
./scripts/manage-secrets.sh rotate dev  # This will fix missing keys
```

#### AWS Credentials Issues
```
Error: AWS credentials are not configured or invalid
```
**Solution:** Configure AWS credentials:
```bash
aws configure
# or
export AWS_PROFILE=your-profile
```

#### SES Domain Not Verified
```
Warning: SES domain verification status for yourdomain.com: Pending
```
**Solution:** Complete domain verification in the AWS SES console or wait for DNS propagation.