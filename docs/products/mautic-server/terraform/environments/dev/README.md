# Mautic Development Environment

This directory contains the Terraform configuration for deploying Mautic in the development environment using private modules.

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform >= 1.0** installed
3. **AWS Secrets Manager secret** created (see below)
4. **S3 bucket and DynamoDB table** for Terraform state (see Backend Setup)

### 1. Create AWS Secrets Manager Secret

Create a secret named `mautic-dev-secrets` with this structure:

```json
{
  "database_password": "your-secure-db-password-min-8-chars",
  "mautic_secret_key": "your-32-character-mautic-secret-key-here",
  "admin_credentials": {
    "admin_email": "admin@yourdomain.com",
    "admin_password": "your-secure-admin-password",
    "admin_firstname": "Admin",
    "admin_lastname": "User"
  },
  "email_configuration": {
    "smtp_host": "email-smtp.us-east-1.amazonaws.com",
    "smtp_port": "587",
    "smtp_username": "your-ses-smtp-username",
    "smtp_password": "your-ses-smtp-password",
    "from_email": "noreply@yourdomain.com",
    "from_name": "Your Company Mautic"
  }
}
```

### 2. Backend Setup (One-time)

Ensure these resources exist:
- **S3 Bucket**: `terraform-state-YOUR_AWS_ACCOUNT_ID-mautic-server`
  - Versioning enabled
  - Server-side encryption enabled
- **DynamoDB Table**: `terraform-locks`
  - Primary key: `LockID` (String)
  - Billing mode: On-demand

### 3. Deploy

```bash
# Initialize Terraform with backend
terraform init -backend-config=backend.hcl

# Review the plan
terraform plan -var-file=terraform.tfvars

# Deploy the infrastructure
terraform apply -var-file=terraform.tfvars
```

## 📋 What Gets Deployed

### Core Infrastructure
- **VPC** with public/private subnets and NAT Gateway
- **RDS MySQL** database (db.t3.micro, 20GB storage)
- **ECS Fargate** cluster for container orchestration
- **Application Load Balancer** with WAF protection
- **CloudWatch** monitoring and logging

### Security Features
- **AWS WAF** with rate limiting and managed rule sets
- **Security Groups** with least-privilege access
- **Secrets Manager** integration for sensitive data
- **VPC** with private subnets for database and application

### Cost Optimization (Dev Environment)
- Single NAT Gateway (instead of multi-AZ)
- Minimal database instance (db.t3.micro)
- Short log retention (3 days)
- Monitoring alerts disabled
- Single ECS task instance

## 🔧 Configuration

### Key Files
- `main.tf` - Main infrastructure configuration
- `variables.tf` - Variable definitions with validation
- `terraform.tfvars` - Environment-specific values
- `outputs.tf` - Resource outputs and URLs
- `validate-secrets.tf` - Secrets validation logic
- `backend.hcl` - Terraform state backend configuration

### Customization
Edit `terraform.tfvars` to customize:
- Domain configuration
- SSL certificates
- WAF settings
- Resource tags
- Monitoring preferences

## 📊 Accessing Your Deployment

After successful deployment, Terraform will output:
- **Mautic URL**: Access your Mautic application
- **Admin URL**: Direct link to Mautic admin login
- **Database Endpoint**: For direct database access (if needed)
- **Monitoring Dashboard**: CloudWatch dashboard URL

## 🛠 Troubleshooting

### Common Issues

1. **Secrets Validation Failed**
   - Ensure the secret exists in AWS Secrets Manager
   - Verify the JSON structure matches the required format
   - Check that all required fields are present

2. **Backend Initialization Failed**
   - Verify S3 bucket exists and you have access
   - Ensure DynamoDB table exists with correct primary key
   - Check AWS credentials and permissions

3. **Resource Creation Failed**
   - Review AWS service limits in your account
   - Ensure you have necessary IAM permissions
   - Check for resource naming conflicts

### Useful Commands

```bash
# View current state
terraform show

# List all resources
terraform state list

# Get specific output
terraform output mautic_url

# Destroy everything (careful!)
terraform destroy -var-file=terraform.tfvars
```

## 🔒 Security Notes

- Database is deployed in private subnets (not internet accessible)
- WAF provides protection against common web attacks
- All sensitive data is stored in AWS Secrets Manager
- Security groups follow least-privilege principles
- Encryption is enabled for database and state storage

## 💰 Cost Estimation

Approximate monthly costs for dev environment:
- **ECS Fargate**: ~$15-25/month (single task)
- **RDS db.t3.micro**: ~$15-20/month
- **NAT Gateway**: ~$45/month (largest cost component)
- **Load Balancer**: ~$20/month
- **Other services**: ~$5-10/month

**Total**: ~$100-120/month

To reduce costs further:
- Use Fargate Spot instances (set in variables)
- Reduce NAT Gateway usage (deploy in public subnets for testing)
- Use smaller RDS instance or Aurora Serverless

## 📚 Additional Resources

- [Mautic Documentation](https://docs.mautic.org/)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)