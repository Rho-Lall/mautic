# Basic Lead Capture Setup Example

This example demonstrates how to deploy a complete serverless lead capture system using all the provided Terraform modules.

## Architecture

This example creates:
- **DynamoDB Table**: Stores lead data with encryption at rest
- **Lambda Functions**: Handle form submissions and lead retrieval
- **API Gateway**: Provides REST API endpoints with CORS support
- **SES Configuration** (optional): Email notifications for new leads

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform >= 1.0** installed
3. **Lambda deployment packages** built and available as ZIP files
4. **Domain and SSL certificate** (optional, for custom domain)

## Quick Start

1. **Clone the repository and navigate to this example:**
   ```bash
   cd terraform/examples/basic-setup
   ```

2. **Create Lambda deployment packages:**
   ```bash
   # Build your Lambda functions and create ZIP files
   # Place them in the dist/ directory or update the paths in terraform.tfvars
   ```

3. **Create a terraform.tfvars file:**
   ```hcl
   aws_region = "us-east-1"
   
   # Lambda deployment packages
   submit_lambda_zip_path = "../../../dist/submit-lead.zip"
   get_lambda_zip_path    = "../../../dist/get-leads.zip"
   
   # CORS configuration
   cors_allow_origin = "https://your-website.com"
   
   # API security
   enable_api_key = true
   
   # Optional: Custom domain
   custom_domain_name = "api.your-domain.com"
   certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
   
   # Optional: Email notifications
   enable_email_notifications = true
   sender_emails              = ["noreply@your-domain.com"]
   ses_domain_name           = "your-domain.com"
   ```

4. **Initialize and deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Get the API endpoint and key:**
   ```bash
   terraform output api_gateway_url
   terraform output -raw api_key_value
   ```

## Configuration Options

### Basic Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for deployment | `us-east-1` | No |
| `submit_lambda_zip_path` | Path to submit Lambda ZIP | `../../../dist/submit-lead.zip` | Yes |
| `get_lambda_zip_path` | Path to get Lambda ZIP | `../../../dist/get-leads.zip` | Yes |
| `cors_allow_origin` | CORS allowed origin | `*` | No |

### Security Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `enable_api_key` | Enable API key authentication | `true` | No |

### Custom Domain Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `custom_domain_name` | Custom domain for API | `""` | No |
| `certificate_arn` | SSL certificate ARN | `""` | No* |

*Required if `custom_domain_name` is set

### Email Notifications Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `enable_email_notifications` | Enable SES notifications | `false` | No |
| `sender_emails` | Verified sender emails | `[]` | No* |
| `ses_domain_name` | SES domain name | `""` | No |
| `mail_from_domain` | Custom MAIL FROM domain | `""` | No |
| `enable_welcome_email` | Enable welcome emails | `false` | No |

*Required if `enable_email_notifications` is `true`

## Outputs

After deployment, you'll get:

- **API Gateway URL**: The endpoint for your lead capture form
- **API Key**: Authentication key for form submissions (if enabled)
- **DynamoDB Table Name**: Where leads are stored
- **Lambda Function Names**: For monitoring and debugging
- **SES Configuration**: Email setup details (if enabled)
- **Form Integration Example**: HTML code to embed in your website

## Form Integration

Use the output `form_integration_example` to get the exact HTML code for your website:

```html
<!-- Lead Capture Form Integration -->
<script src="https://your-cdn.com/lead-capture.js"></script>
<div id="lead-capture-form" 
     data-api-endpoint="https://your-api-endpoint.com/leads"
     data-api-key="your-api-key-here"
     data-fields="name,email,company">
</div>
```

## Monitoring

The example includes:
- **CloudWatch Logs**: For Lambda function execution logs
- **CloudWatch Alarms**: For error rates and performance monitoring
- **DynamoDB Metrics**: For database performance
- **SES Metrics**: For email delivery monitoring (if enabled)

## Cost Optimization

This example uses:
- **DynamoDB Pay-per-Request**: No fixed costs, pay only for usage
- **Lambda**: Pay per invocation and execution time
- **API Gateway**: Pay per API call
- **SES**: Pay per email sent (if enabled)

For production workloads with predictable traffic, consider switching to provisioned capacity for DynamoDB.

## Security Features

- **Encryption at rest**: DynamoDB table encrypted with KMS
- **CORS protection**: Configurable allowed origins
- **API key authentication**: Optional API key requirement
- **IAM least privilege**: Minimal required permissions
- **Input validation**: Lambda functions validate all inputs
- **Rate limiting**: API Gateway throttling configured

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all data in the DynamoDB table.

## Next Steps

1. **Deploy your Lambda functions**: Build and package your actual Lambda code
2. **Configure your domain**: Set up custom domain and SSL certificate
3. **Set up monitoring**: Configure CloudWatch dashboards and alerts
4. **Test the integration**: Embed the form in your website and test submissions
5. **Configure email notifications**: Set up SES for lead notifications

## Troubleshooting

### Common Issues

1. **Lambda ZIP files not found**: Ensure the paths in `terraform.tfvars` are correct
2. **Certificate validation failed**: Ensure the SSL certificate is validated in ACM
3. **SES domain not verified**: Complete domain verification in SES console
4. **CORS errors**: Check that `cors_allow_origin` matches your website domain

### Getting Help

- Check CloudWatch logs for Lambda function errors
- Review API Gateway execution logs
- Verify DynamoDB table permissions
- Test API endpoints directly with curl or Postman