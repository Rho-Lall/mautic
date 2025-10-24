# Terraform Infrastructure for Serverless Lead Capture

This directory contains Terraform modules and examples for deploying a serverless lead capture system on AWS. The infrastructure is designed to be modular, secure, and production-ready.

## Architecture Overview

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│   GitHub Pages  │───▶│ API Gateway  │───▶│   Lambda    │───▶│  DynamoDB   │
│   (Lead Form)   │    │   (CORS)     │    │ Functions   │    │ (Encrypted) │
└─────────────────┘    └──────────────┘    └─────────────┘    └─────────────┘
                              │                     │                 │
                              ▼                     ▼                 ▼
                       ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
                       │ CloudWatch   │    │     SES     │    │   Streams   │
                       │ (Monitoring) │    │  (Emails)   │    │ (Optional)  │
                       └──────────────┘    └─────────────┘    └─────────────┘
```

## Directory Structure

```
terraform/
├── modules/                    # Reusable Terraform modules
│   ├── api-gateway/           # API Gateway REST API with CORS
│   ├── dynamodb/              # DynamoDB table with encryption
│   ├── lambda/                # Lambda functions with IAM roles
│   └── ses/                   # SES email service configuration
├── examples/                  # Complete deployment examples
│   ├── basic-setup/           # Simple development setup
│   └── production-setup/      # Production-ready configuration
└── README.md                  # This file
```

## Modules

### [API Gateway Module](./modules/api-gateway/)
Creates a REST API with CORS support, optional custom domain, and API key authentication.

**Key Features:**
- Regional API Gateway with CORS configuration
- POST /leads endpoint for form submissions
- GET /leads endpoint for data retrieval (IAM authenticated)
- Optional custom domain with SSL certificate
- API key authentication with usage plans and throttling
- Lambda proxy integration

**Outputs:**
- API Gateway URL and custom domain URL
- API key value (sensitive)
- Resource IDs for integration

### [Lambda Module](./modules/lambda/)
Deploys Lambda functions for processing lead submissions and retrievals with proper IAM roles.

**Key Features:**
- Submit lead and get leads Lambda functions
- IAM execution roles with least-privilege permissions
- CloudWatch log groups with configurable retention
- Environment variable management
- Optional SES permissions for email notifications
- CloudWatch alarms for error monitoring

**Outputs:**
- Lambda function names and ARNs
- Invoke ARNs for API Gateway integration
- Log group names and ARNs

### [DynamoDB Module](./modules/dynamodb/)
Creates a DynamoDB table for storing lead data with encryption, backup, and monitoring.

**Key Features:**
- Encrypted table with customer-managed KMS key
- Global Secondary Indexes for email and source queries
- Point-in-time recovery and optional backups
- Auto-scaling for provisioned capacity mode
- TTL support for GDPR compliance
- DynamoDB streams for real-time processing
- CloudWatch alarms for throttling detection

**Outputs:**
- Table name, ARN, and stream ARN
- KMS key information
- GSI names and configuration details

### [SES Module](./modules/ses/)
Configures AWS SES for sending email notifications with templates and bounce handling.

**Key Features:**
- Domain and email address verification
- DKIM authentication setup
- Email templates for lead notifications and welcome emails
- Bounce and complaint handling via SNS
- CloudWatch logging and monitoring
- IAM roles for Lambda integration
- Configuration sets for organized sending

**Outputs:**
- Domain verification tokens and DKIM records
- Template names and configuration set details
- SNS topic ARN for bounce handling
- IAM role ARN for Lambda integration

## Examples

### [Basic Setup](./examples/basic-setup/)
A simple deployment suitable for development and testing.

**Includes:**
- Pay-per-request DynamoDB billing
- Basic monitoring and logging
- Optional SES integration
- Minimal configuration requirements

**Use Cases:**
- Development environments
- Proof of concept deployments
- Low-traffic websites
- Learning and experimentation

### [Production Setup](./examples/production-setup/)
A comprehensive production-ready deployment with all security and monitoring features.

**Includes:**
- Configurable DynamoDB capacity modes
- Comprehensive CloudWatch monitoring
- SNS alerting and notifications
- Custom email templates
- GDPR compliance features
- Cost optimization options

**Use Cases:**
- Production websites
- High-traffic applications
- Enterprise deployments
- Compliance-sensitive environments

## Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **Lambda deployment packages** built as ZIP files
4. **Domain and SSL certificate** (optional, for custom domain)

### Basic Deployment

```bash
# Clone the repository
git clone <repository-url>
cd terraform/examples/basic-setup

# Create terraform.tfvars
cat > terraform.tfvars << EOF
aws_region = "us-east-1"
submit_lambda_zip_path = "../../../dist/submit-lead.zip"
get_lambda_zip_path = "../../../dist/get-leads.zip"
cors_allow_origin = "https://your-website.com"
enable_api_key = true
EOF

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

### Production Deployment

```bash
cd terraform/examples/production-setup

# Create comprehensive terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration

# Deploy with approval
terraform init
terraform plan
terraform apply
```

## Module Integration Patterns

### Complete Stack Integration

```hcl
# DynamoDB for data storage
module "dynamodb" {
  source = "./modules/dynamodb"
  # ... configuration
}

# Lambda functions for processing
module "lambda" {
  source = "./modules/lambda"
  
  # Integration with DynamoDB
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn
  # ... other configuration
}

# API Gateway for HTTP endpoints
module "api_gateway" {
  source = "./modules/api-gateway"
  
  # Integration with Lambda
  submit_lambda_invoke_arn    = module.lambda.submit_lambda_invoke_arn
  get_lambda_invoke_arn       = module.lambda.get_lambda_invoke_arn
  submit_lambda_function_name = module.lambda.submit_lambda_function_name
  get_lambda_function_name    = module.lambda.get_lambda_function_name
  # ... other configuration
}

# Optional SES for email notifications
module "ses" {
  source = "./modules/ses"
  # ... configuration
}
```

### Partial Integration

You can use individual modules for specific needs:

```hcl
# Just DynamoDB for data storage
module "dynamodb" {
  source = "./modules/dynamodb"
  
  table_name    = "my-leads-table"
  billing_mode  = "PAY_PER_REQUEST"
  enable_encryption = true
}

# Use outputs in other resources
resource "aws_lambda_function" "my_function" {
  # ... configuration
  
  environment {
    variables = {
      DYNAMODB_TABLE_NAME = module.dynamodb.table_name
    }
  }
}
```

## Configuration Best Practices

### Environment-Specific Configuration

Use Terraform workspaces or separate directories for different environments:

```bash
# Using workspaces
terraform workspace new development
terraform workspace new production

# Using separate directories
mkdir -p environments/{dev,staging,prod}
```

### Variable Management

Use `.tfvars` files for environment-specific values:

```hcl
# dev.tfvars
environment = "dev"
enable_monitoring = false
log_retention_days = 7

# prod.tfvars
environment = "prod"
enable_monitoring = true
log_retention_days = 90
```

### State Management

Use remote state for team collaboration:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "lead-capture/terraform.tfstate"
    region = "us-east-1"
    
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

## Security Considerations

### Data Protection
- **Encryption at Rest**: All data encrypted with KMS
- **Encryption in Transit**: HTTPS/TLS for all communications
- **Access Control**: IAM roles with least-privilege principles
- **Input Validation**: Server-side validation and sanitization

### Network Security
- **CORS Protection**: Configurable allowed origins
- **API Authentication**: API key or IAM-based authentication
- **Rate Limiting**: Throttling and quota management
- **VPC Integration**: Optional VPC deployment for Lambda functions

### Compliance
- **GDPR Ready**: TTL for automatic data expiration
- **Audit Logging**: CloudTrail integration
- **Data Backup**: Point-in-time recovery and backups
- **Monitoring**: Comprehensive logging and alerting

## Cost Optimization

### DynamoDB Billing Modes

| Mode | Best For | Cost Structure |
|------|----------|----------------|
| Pay-per-Request | Variable traffic | $1.25 per million requests |
| Provisioned | Predictable traffic | $0.25 per RCU/WCU per month |

### Lambda Optimization
- **Memory Sizing**: Balance performance vs. cost
- **Execution Time**: Optimize code for faster execution
- **Provisioned Concurrency**: For consistent performance (additional cost)

### Monitoring Costs
- **CloudWatch Logs**: Configure appropriate retention periods
- **CloudWatch Metrics**: Use custom metrics judiciously
- **Alarms**: Set up only necessary alarms

## Monitoring and Observability

### CloudWatch Integration
- **Lambda Metrics**: Invocations, errors, duration
- **DynamoDB Metrics**: Read/write capacity, throttling
- **API Gateway Metrics**: Request count, latency, errors
- **SES Metrics**: Send, bounce, complaint rates

### Alerting Strategy
- **Error Rate Alarms**: Lambda function errors
- **Performance Alarms**: High latency or duration
- **Capacity Alarms**: DynamoDB throttling
- **Email Reputation**: SES bounce/complaint rates

### Logging Best Practices
- **Structured Logging**: Use JSON format for logs
- **Log Levels**: Configure appropriate verbosity
- **Retention Policies**: Balance cost vs. compliance needs
- **Centralized Logging**: Consider log aggregation solutions

## Troubleshooting

### Common Issues

#### Terraform Deployment Issues
```bash
# Check Terraform version
terraform version

# Validate configuration
terraform validate

# Check state
terraform show
```

#### Lambda Function Issues
```bash
# Check function logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/"

# Test function directly
aws lambda invoke --function-name function-name output.json
```

#### DynamoDB Issues
```bash
# Check table status
aws dynamodb describe-table --table-name table-name

# Monitor metrics
aws cloudwatch get-metric-statistics --namespace AWS/DynamoDB
```

#### API Gateway Issues
```bash
# Test endpoint
curl -X POST https://api-url/leads \
  -H "Content-Type: application/json" \
  -H "X-API-Key: api-key" \
  -d '{"test": "data"}'

# Check API Gateway logs
aws logs describe-log-groups --log-group-name-prefix "API-Gateway-Execution-Logs"
```

### Debug Mode

Enable detailed logging for troubleshooting:

```hcl
# In Lambda module
log_level = "DEBUG"

# In API Gateway
enable_logging = true
log_level = "INFO"
```

## Contributing

### Module Development
1. **Follow Conventions**: Use consistent naming and structure
2. **Add Validation**: Include variable validation rules
3. **Document Changes**: Update README files
4. **Test Thoroughly**: Test in multiple environments

### Example Development
1. **Real-world Scenarios**: Create practical examples
2. **Complete Documentation**: Include setup and troubleshooting
3. **Variable Examples**: Provide sample configurations
4. **Output Documentation**: Explain all outputs

## Support and Resources

### AWS Documentation
- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/)
- [Amazon DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/)
- [Amazon API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/latest/developerguide/)
- [Amazon SES Developer Guide](https://docs.aws.amazon.com/ses/latest/dg/)

### Terraform Resources
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

### Community
- [AWS Community Forums](https://forums.aws.amazon.com/)
- [Terraform Community](https://discuss.hashicorp.com/c/terraform-core/)

## License

This project is licensed under the MIT License - see the LICENSE file for details.