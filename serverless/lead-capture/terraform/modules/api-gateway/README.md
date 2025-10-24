# API Gateway Module

This Terraform module creates an AWS API Gateway REST API for the serverless lead capture system with CORS support, optional custom domain, and API key authentication.

## Features

- **REST API Gateway** with regional endpoint configuration
- **CORS support** for cross-origin requests from web forms
- **API key authentication** with usage plans and throttling
- **Custom domain support** with SSL certificate integration
- **Lambda integration** for POST and GET endpoints
- **Request validation** for input data
- **CloudWatch monitoring** integration

## Usage

### Basic Usage

```hcl
module "api_gateway" {
  source = "./modules/api-gateway"

  api_name        = "lead-capture-api"
  api_description = "API Gateway for lead capture form"
  stage_name      = "prod"

  # Lambda function integration
  submit_lambda_invoke_arn    = module.lambda.submit_lambda_invoke_arn
  get_lambda_invoke_arn       = module.lambda.get_lambda_invoke_arn
  submit_lambda_function_name = module.lambda.submit_lambda_function_name
  get_lambda_function_name    = module.lambda.get_lambda_function_name

  # CORS configuration
  cors_allow_origin = "https://your-website.com"

  tags = {
    Environment = "production"
    Project     = "lead-capture"
  }
}
```

### With Custom Domain

```hcl
module "api_gateway" {
  source = "./modules/api-gateway"

  api_name        = "lead-capture-api"
  stage_name      = "prod"

  # Lambda integration
  submit_lambda_invoke_arn    = module.lambda.submit_lambda_invoke_arn
  get_lambda_invoke_arn       = module.lambda.get_lambda_invoke_arn
  submit_lambda_function_name = module.lambda.submit_lambda_function_name
  get_lambda_function_name    = module.lambda.get_lambda_function_name

  # Custom domain configuration
  custom_domain_name = "api.example.com"
  certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

  # CORS and security
  cors_allow_origin = "https://example.com"
  enable_api_key    = true
}
```

### With API Key and Rate Limiting

```hcl
module "api_gateway" {
  source = "./modules/api-gateway"

  api_name   = "lead-capture-api"
  stage_name = "prod"

  # Lambda integration
  submit_lambda_invoke_arn    = module.lambda.submit_lambda_invoke_arn
  get_lambda_invoke_arn       = module.lambda.get_lambda_invoke_arn
  submit_lambda_function_name = module.lambda.submit_lambda_function_name
  get_lambda_function_name    = module.lambda.get_lambda_function_name

  # API key and rate limiting
  enable_api_key          = true
  quota_limit             = 5000
  quota_period            = "DAY"
  throttle_rate_limit     = 50
  throttle_burst_limit    = 100

  cors_allow_origin = "https://your-website.com"
}
```

## Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `submit_lambda_invoke_arn` | Invoke ARN of the submit lead Lambda function | `string` |
| `get_lambda_invoke_arn` | Invoke ARN of the get leads Lambda function | `string` |
| `submit_lambda_function_name` | Name of the submit lead Lambda function | `string` |
| `get_lambda_function_name` | Name of the get leads Lambda function | `string` |

### Optional Variables

| Name | Description | Type | Default | Validation |
|------|-------------|------|---------|------------|
| `api_name` | Name of the API Gateway | `string` | `"lead-capture-api"` | - |
| `api_description` | Description of the API Gateway | `string` | `"API Gateway for serverless lead capture form"` | - |
| `stage_name` | Name of the API Gateway stage | `string` | `"prod"` | - |
| `cors_allow_origin` | CORS allowed origin for API requests | `string` | `"'*'"` | - |
| `custom_domain_name` | Custom domain name for the API Gateway (optional) | `string` | `""` | - |
| `certificate_arn` | ARN of the SSL certificate for custom domain | `string` | `""` | Required if `custom_domain_name` is set |
| `enable_api_key` | Enable API key authentication | `bool` | `true` | - |
| `quota_limit` | API usage quota limit | `number` | `10000` | - |
| `quota_period` | API usage quota period | `string` | `"DAY"` | Must be one of: `DAY`, `WEEK`, `MONTH` |
| `throttle_rate_limit` | API throttle rate limit (requests per second) | `number` | `100` | - |
| `throttle_burst_limit` | API throttle burst limit | `number` | `200` | - |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` | - |

### Variable Validation Rules

#### quota_period
```hcl
validation {
  condition     = contains(["DAY", "WEEK", "MONTH"], var.quota_period)
  error_message = "Quota period must be one of: DAY, WEEK, MONTH."
}
```

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `api_gateway_id` | ID of the API Gateway | No |
| `api_gateway_arn` | ARN of the API Gateway | No |
| `api_gateway_execution_arn` | Execution ARN of the API Gateway | No |
| `api_gateway_url` | URL of the API Gateway | No |
| `custom_domain_url` | URL of the custom domain (if configured) | No |
| `api_key_id` | ID of the API key (if enabled) | No |
| `api_key_value` | Value of the API key (if enabled) | Yes |
| `usage_plan_id` | ID of the usage plan (if API key is enabled) | No |
| `stage_name` | Name of the API Gateway stage | No |
| `leads_resource_id` | ID of the leads resource | No |

## API Endpoints

The module creates the following endpoints:

### POST /leads
- **Purpose**: Submit new lead data
- **Authentication**: API key (if enabled)
- **CORS**: Enabled with preflight support
- **Integration**: Lambda proxy integration with submit Lambda function

### GET /leads
- **Purpose**: Retrieve stored leads
- **Authentication**: AWS IAM (for administrative access)
- **Integration**: Lambda proxy integration with get Lambda function

### OPTIONS /leads
- **Purpose**: CORS preflight requests
- **Authentication**: None
- **Response**: CORS headers for browser compatibility

## Security Features

- **API Key Authentication**: Optional API key requirement for form submissions
- **CORS Protection**: Configurable allowed origins to prevent unauthorized access
- **Request Validation**: Built-in request validator for input data
- **IAM Integration**: GET endpoint requires AWS IAM authentication
- **Rate Limiting**: Configurable throttling and quota limits
- **SSL/TLS**: HTTPS-only endpoints with optional custom domain support

## Monitoring and Logging

The module integrates with AWS CloudWatch for:
- **API Gateway Logs**: Request/response logging
- **CloudWatch Metrics**: API performance and error metrics
- **Usage Metrics**: API key usage tracking
- **Throttling Metrics**: Rate limiting effectiveness

## Custom Domain Setup

To use a custom domain:

1. **Create SSL Certificate** in AWS Certificate Manager
2. **Validate the certificate** (DNS or email validation)
3. **Set variables**:
   ```hcl
   custom_domain_name = "api.yourdomain.com"
   certificate_arn    = "arn:aws:acm:region:account:certificate/cert-id"
   ```
4. **Create DNS record** pointing to the API Gateway domain name

## CORS Configuration

The module automatically configures CORS for web form integration:

- **Allowed Methods**: GET, POST, OPTIONS
- **Allowed Headers**: Content-Type, X-Amz-Date, Authorization, X-Api-Key, X-Amz-Security-Token
- **Allowed Origins**: Configurable via `cors_allow_origin` variable

For multiple origins, you may need to handle this in your Lambda function.

## Rate Limiting

API Gateway provides two levels of rate limiting:

1. **Throttling**: Per-second request limits
   - `throttle_rate_limit`: Steady-state request rate
   - `throttle_burst_limit`: Maximum burst capacity

2. **Quotas**: Longer-term usage limits
   - `quota_limit`: Total requests per period
   - `quota_period`: Time period (DAY, WEEK, MONTH)

## Dependencies

This module requires:
- **Lambda functions**: Submit and get lead Lambda functions must exist
- **AWS Provider**: Version ~> 5.0
- **Terraform**: Version >= 1.0

## Integration with Other Modules

This module is designed to work with:
- **Lambda Module**: Provides the backend functions
- **DynamoDB Module**: Stores the lead data
- **SES Module**: Optional email notifications

## Troubleshooting

### Common Issues

1. **CORS Errors**: Ensure `cors_allow_origin` matches your website domain exactly
2. **API Key Issues**: Check that the API key is included in requests as `X-API-Key` header
3. **Lambda Permissions**: The module automatically creates necessary Lambda permissions
4. **Custom Domain**: Ensure the SSL certificate is validated and in the same region

### Testing

Test the API endpoints:

```bash
# Test POST endpoint (with API key)
curl -X POST https://your-api-url/prod/leads \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{"name":"Test","email":"test@example.com"}'

# Test OPTIONS endpoint (CORS preflight)
curl -X OPTIONS https://your-api-url/prod/leads \
  -H "Origin: https://your-website.com"
```