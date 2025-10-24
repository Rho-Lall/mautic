# Production Lead Capture Setup

This example demonstrates a production-ready deployment of the serverless lead capture system with comprehensive security, monitoring, and operational features.

## Features

- **Production Security**: Full encryption, API keys, CORS protection
- **High Availability**: Auto-scaling, point-in-time recovery, monitoring
- **Compliance**: GDPR-ready with TTL, audit logging, data encryption
- **Monitoring**: CloudWatch dashboard, alarms, SNS notifications
- **Cost Optimization**: Configurable capacity modes, log retention
- **Operational Excellence**: Comprehensive outputs, documentation

## Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐
│   GitHub Pages  │───▶│ API Gateway  │───▶│   Lambda    │
│   (Lead Form)   │    │ (Custom DNS) │    │ Functions   │
└─────────────────┘    └──────────────┘    └─────────────┘
                              │                     │
                              ▼                     ▼
                       ┌──────────────┐    ┌─────────────┐
                       │ CloudWatch   │    │  DynamoDB   │
                       │ (Monitoring) │    │ (Encrypted) │
                       └──────────────┘    └─────────────┘
                              │                     │
                              ▼                     ▼
                       ┌──────────────┐    ┌─────────────┐
                       │     SNS      │    │     SES     │
                       │  (Alerts)    │    │  (Emails)   │
                       └──────────────┘    └─────────────┘
```

## Prerequisites

### AWS Account Setup
1. **AWS CLI configured** with administrative permissions
2. **Domain registered** and managed in Route 53 (optional)
3. **SSL certificate** created in AWS Certificate Manager
4. **SES domain verified** (if using email notifications)

### Development Environment
1. **Terraform >= 1.0** installed
2. **Lambda deployment packages** built and available
3. **Environment variables** configured for production

## Quick Start

### 1. Prepare Lambda Packages

Build your Lambda functions and create deployment packages:

```bash
# Build and package Lambda functions
cd src/lambda
npm install --production
zip -r ../../dist/submit-lead.zip .
zip -r ../../dist/get-leads.zip .
```

### 2. Configure Variables

Create `terraform.tfvars`:

```hcl
# Basic Configuration
aws_region = "us-east-1"

# Lambda Packages
submit_lambda_zip_path = "./dist/submit-lead.zip"
get_lambda_zip_path    = "./dist/get-leads.zip"

# API Configuration
cors_allow_origin    = "https://mywebsite.com"
custom_domain_name   = "api.mywebsite.com"
certificate_arn      = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

# Rate Limiting
daily_quota_limit     = 100000
throttle_rate_limit   = 500
throttle_burst_limit  = 1000

# DynamoDB Configuration
use_provisioned_capacity = false  # Use pay-per-request for variable traffic
enable_data_retention   = true    # Enable TTL for GDPR compliance
enable_real_time_processing = false  # Enable if you need DynamoDB streams

# Email Configuration
enable_email_notifications = true
ses_domain_name           = "mywebsite.com"
sender_emails            = ["noreply@mywebsite.com", "admin@mywebsite.com"]
mail_from_domain         = "mail.mywebsite.com"
enable_welcome_email     = true
website_name            = "My Website"
company_name            = "My Company"

# Monitoring
alert_email_addresses = ["admin@mywebsite.com", "ops@mywebsite.com"]

# Environment Variables
submit_lambda_environment_variables = {
  WEBHOOK_URL = "https://webhook.mywebsite.com/leads"
  SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/..."
}
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

### 4. Configure DNS Records

After deployment, configure the required DNS records (see outputs):

```bash
# Get DNS configuration
terraform output dns_configuration
```

### 5. Test the Deployment

```bash
# Get API endpoint and key
API_ENDPOINT=$(terraform output -raw api_gateway_url)
API_KEY=$(terraform output -raw api_key_value)

# Test form submission
curl -X POST "${API_ENDPOINT}/leads" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY}" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "company": "Test Company",
    "message": "This is a test submission"
  }'
```

## Configuration Options

### DynamoDB Capacity Management

#### Pay-per-Request (Recommended for Variable Traffic)
```hcl
use_provisioned_capacity = false
```

#### Provisioned Capacity (For Predictable Traffic)
```hcl
use_provisioned_capacity = true
initial_read_capacity    = 20
initial_write_capacity   = 20
read_min_capacity       = 10
read_max_capacity       = 500
write_min_capacity      = 10
write_max_capacity      = 500
```

### Email Notification Templates

#### Custom Lead Notification Template
```hcl
custom_notification_template = <<-EOT
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>New Lead Alert</title>
    <style>
        body { font-family: Arial, sans-serif; }
        .header { background-color: #f8f9fa; padding: 20px; }
        .content { padding: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>New Lead from {{source}}</h1>
    </div>
    <div class="content">
        <h2>Contact Information</h2>
        <p><strong>Name:</strong> {{name}}</p>
        <p><strong>Email:</strong> {{email}}</p>
        <p><strong>Company:</strong> {{company}}</p>
        <p><strong>Phone:</strong> {{phone}}</p>
        <p><strong>Message:</strong> {{message}}</p>
        <p><strong>Submitted:</strong> {{timestamp}}</p>
    </div>
</body>
</html>
EOT
```

### Advanced Lambda Configuration

```hcl
submit_lambda_environment_variables = {
  # Webhook Integration
  WEBHOOK_URL = "https://webhook.example.com/leads"
  WEBHOOK_SECRET = "your-webhook-secret"
  
  # Slack Integration
  SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/..."
  SLACK_CHANNEL = "#leads"
  
  # Rate Limiting
  RATE_LIMIT_WINDOW = "3600"  # 1 hour
  RATE_LIMIT_MAX_REQUESTS = "100"
  
  # Spam Protection
  SPAM_PROTECTION_ENABLED = "true"
  HONEYPOT_FIELD_NAME = "website"
  
  # Data Validation
  REQUIRED_FIELDS = "name,email"
  MAX_MESSAGE_LENGTH = "1000"
}
```

## Security Features

### Data Protection
- **Encryption at Rest**: DynamoDB encrypted with customer-managed KMS keys
- **Encryption in Transit**: HTTPS/TLS for all communications
- **API Key Authentication**: Required for form submissions
- **CORS Protection**: Configurable allowed origins
- **Input Validation**: Server-side validation and sanitization

### Access Control
- **IAM Least Privilege**: Minimal required permissions
- **Lambda Execution Roles**: Separate roles with specific permissions
- **API Gateway Authorization**: IAM-based access for admin endpoints
- **SES Sending Restrictions**: Limited to verified addresses

### Compliance
- **GDPR Ready**: TTL for automatic data expiration
- **Audit Logging**: CloudTrail integration for API calls
- **Data Backup**: Point-in-time recovery enabled
- **Monitoring**: Comprehensive logging and alerting

## Monitoring and Alerting

### CloudWatch Dashboard
Access the dashboard: `terraform output cloudwatch_dashboard_url`

**Metrics Included:**
- Lambda function invocations, errors, and duration
- DynamoDB read/write capacity and throttling
- API Gateway request count and error rates
- SES bounce and complaint rates (if enabled)

### CloudWatch Alarms
- **High Error Rate**: Lambda function errors exceed threshold
- **DynamoDB Throttling**: Database requests being throttled
- **SES Bounce Rate**: Email bounce rate too high
- **SES Complaint Rate**: Email complaint rate too high

### SNS Notifications
Configure email addresses to receive alerts:
```hcl
alert_email_addresses = [
  "admin@example.com",
  "ops@example.com"
]
```

## Cost Optimization

### Billing Mode Comparison

| Traffic Pattern | Recommended Mode | Cost Characteristics |
|-----------------|------------------|---------------------|
| Unpredictable, bursty | Pay-per-Request | Higher per-request cost, no minimum |
| Consistent, predictable | Provisioned | Lower per-request cost, minimum charges |
| Mixed patterns | Pay-per-Request | Easier management, automatic scaling |

### Cost Monitoring
- **DynamoDB**: Monitor read/write capacity utilization
- **Lambda**: Optimize memory allocation and execution time
- **API Gateway**: Track request volume and caching opportunities
- **CloudWatch**: Review log retention policies

### Optimization Recommendations
1. **Right-size Lambda memory** based on performance testing
2. **Use DynamoDB auto-scaling** for provisioned mode
3. **Implement API caching** for frequently accessed data
4. **Review log retention** policies regularly

## Operational Procedures

### Deployment Process
1. **Build Lambda packages** with production dependencies
2. **Run Terraform plan** to review changes
3. **Apply changes** during maintenance window
4. **Verify deployment** with test requests
5. **Monitor metrics** for any issues

### Backup and Recovery
- **DynamoDB**: 35-day point-in-time recovery window
- **Lambda Code**: Maintain deployment artifacts
- **Terraform State**: Backup state files regularly
- **Configuration**: Version control all configurations

### Scaling Considerations
- **API Gateway**: Automatic scaling, monitor throttling
- **Lambda**: Concurrent execution limits, consider provisioned concurrency
- **DynamoDB**: Auto-scaling for provisioned mode
- **SES**: Request limit increases if needed

## Troubleshooting

### Common Issues

#### High Error Rates
1. Check Lambda function logs in CloudWatch
2. Verify DynamoDB permissions and capacity
3. Test API endpoints directly
4. Review input validation logic

#### Email Delivery Issues
1. Verify SES domain and email addresses
2. Check bounce and complaint rates
3. Review DKIM and SPF records
4. Monitor SES reputation metrics

#### Performance Issues
1. Monitor Lambda duration and memory usage
2. Check DynamoDB throttling metrics
3. Review API Gateway latency
4. Optimize Lambda function code

### Debugging Commands

```bash
# Check Lambda function logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/lead-capture"

# Test API endpoint
curl -X POST "https://api.example.com/leads" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{"name":"Test","email":"test@example.com"}'

# Check DynamoDB table status
aws dynamodb describe-table --table-name lead-capture-leads-prod

# Verify SES domain status
aws ses get-identity-verification-attributes --identities example.com
```

## Maintenance

### Regular Tasks
- **Review CloudWatch metrics** weekly
- **Check error rates and alarms** daily
- **Update Lambda dependencies** monthly
- **Review cost reports** monthly
- **Test backup recovery** quarterly

### Updates and Patches
- **Lambda Runtime**: Update to latest supported versions
- **Dependencies**: Keep npm packages updated
- **Terraform**: Update provider versions
- **AWS Services**: Monitor for new features and improvements

## Support and Documentation

### Additional Resources
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [API Gateway Best Practices](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-basic-concept.html)
- [SES Best Practices](https://docs.aws.amazon.com/ses/latest/dg/best-practices.html)

### Getting Help
1. **Check CloudWatch logs** for detailed error information
2. **Review Terraform outputs** for configuration details
3. **Use AWS CLI** for direct service interaction
4. **Monitor CloudWatch metrics** for performance insights