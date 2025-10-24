# Lambda Module

This Terraform module creates AWS Lambda functions for the serverless lead capture system, including IAM roles, CloudWatch logging, and monitoring alarms.

## Features

- **Dual Lambda Functions**: Submit lead and get leads handlers
- **IAM Role Management**: Least-privilege execution roles with DynamoDB and SES permissions
- **CloudWatch Integration**: Automatic log groups and monitoring alarms
- **Environment Variables**: Configurable runtime environment
- **Security**: Encrypted environment variables and secure IAM policies
- **Monitoring**: Error rate and duration alarms

## Usage

### Basic Usage

```hcl
module "lambda" {
  source = "./modules/lambda"

  function_name_prefix = "lead-capture"
  runtime              = "nodejs18.x"
  timeout              = 30
  memory_size          = 256

  # Lambda deployment packages
  submit_lambda_zip_path = "./dist/submit-lead.zip"
  get_lambda_zip_path    = "./dist/get-leads.zip"

  # DynamoDB configuration
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn

  tags = {
    Environment = "production"
    Project     = "lead-capture"
  }
}
```

### With SES Integration

```hcl
module "lambda" {
  source = "./modules/lambda"

  function_name_prefix = "lead-capture"
  runtime              = "nodejs18.x"

  # Lambda packages
  submit_lambda_zip_path = "./dist/submit-lead.zip"
  get_lambda_zip_path    = "./dist/get-leads.zip"

  # DynamoDB configuration
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn

  # Enable SES for email notifications
  enable_ses = true

  # Custom environment variables
  submit_lambda_environment_variables = {
    SES_FROM_EMAIL = "noreply@example.com"
    NOTIFICATION_EMAIL = "admin@example.com"
  }
}
```

### Production Configuration

```hcl
module "lambda" {
  source = "./modules/lambda"

  function_name_prefix = "lead-capture-prod"
  runtime              = "nodejs18.x"
  timeout              = 15
  memory_size          = 512

  # Lambda packages
  submit_lambda_zip_path = "./dist/submit-lead.zip"
  get_lambda_zip_path    = "./dist/get-leads.zip"

  # DynamoDB configuration
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn

  # Production settings
  cors_allow_origin   = "https://mywebsite.com"
  log_level          = "WARN"
  log_retention_days = 30
  enable_monitoring  = true
  enable_ses         = true

  tags = {
    Environment = "production"
    Project     = "lead-capture"
    Owner       = "platform-team"
  }
}
```

## Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `submit_lambda_zip_path` | Path to the submit lead Lambda function ZIP file | `string` |
| `get_lambda_zip_path` | Path to the get leads Lambda function ZIP file | `string` |
| `dynamodb_table_name` | Name of the DynamoDB table for storing leads | `string` |
| `dynamodb_table_arn` | ARN of the DynamoDB table for storing leads | `string` |

### Optional Variables

| Name | Description | Type | Default | Validation |
|------|-------------|------|---------|------------|
| `function_name_prefix` | Prefix for Lambda function names | `string` | `"lead-capture"` | - |
| `runtime` | Lambda runtime | `string` | `"nodejs18.x"` | Must be supported Lambda runtime |
| `timeout` | Lambda function timeout in seconds | `number` | `30` | Between 1 and 900 seconds |
| `memory_size` | Lambda function memory size in MB | `number` | `256` | Between 128 and 10240 MB |
| `submit_lambda_handler` | Handler for the submit lead Lambda function | `string` | `"submit-lead.handler"` | - |
| `get_lambda_handler` | Handler for the get leads Lambda function | `string` | `"get-leads.handler"` | - |
| `cors_allow_origin` | CORS allowed origin for API requests | `string` | `"*"` | - |
| `log_level` | Log level for Lambda functions | `string` | `"INFO"` | Must be: DEBUG, INFO, WARN, ERROR |
| `log_retention_days` | CloudWatch log retention in days | `number` | `14` | Valid CloudWatch retention period |
| `enable_ses` | Enable SES permissions for Lambda functions | `bool` | `false` | - |
| `enable_monitoring` | Enable CloudWatch monitoring and alarms | `bool` | `true` | - |
| `submit_lambda_environment_variables` | Additional environment variables for submit Lambda | `map(string)` | `{}` | - |
| `get_lambda_environment_variables` | Additional environment variables for get Lambda | `map(string)` | `{}` | - |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` | - |

### Variable Validation Rules

#### runtime
```hcl
validation {
  condition = contains([
    "nodejs14.x", "nodejs16.x", "nodejs18.x", "nodejs20.x",
    "python3.8", "python3.9", "python3.10", "python3.11"
  ], var.runtime)
  error_message = "Runtime must be a supported Lambda runtime version."
}
```

#### timeout
```hcl
validation {
  condition     = var.timeout >= 1 && var.timeout <= 900
  error_message = "Timeout must be between 1 and 900 seconds."
}
```

#### memory_size
```hcl
validation {
  condition     = var.memory_size >= 128 && var.memory_size <= 10240
  error_message = "Memory size must be between 128 and 10240 MB."
}
```

#### log_level
```hcl
validation {
  condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
  error_message = "Log level must be one of: DEBUG, INFO, WARN, ERROR."
}
```

#### log_retention_days
```hcl
validation {
  condition = contains([
    1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
  ], var.log_retention_days)
  error_message = "Log retention days must be a valid CloudWatch retention period."
}
```

## Outputs

| Name | Description |
|------|-------------|
| `submit_lambda_function_name` | Name of the submit lead Lambda function |
| `submit_lambda_function_arn` | ARN of the submit lead Lambda function |
| `submit_lambda_invoke_arn` | Invoke ARN of the submit lead Lambda function |
| `get_lambda_function_name` | Name of the get leads Lambda function |
| `get_lambda_function_arn` | ARN of the get leads Lambda function |
| `get_lambda_invoke_arn` | Invoke ARN of the get leads Lambda function |
| `lambda_execution_role_arn` | ARN of the Lambda execution role |
| `lambda_execution_role_name` | Name of the Lambda execution role |
| `submit_lambda_log_group_name` | Name of the submit Lambda CloudWatch log group |
| `get_lambda_log_group_name` | Name of the get Lambda CloudWatch log group |
| `submit_lambda_log_group_arn` | ARN of the submit Lambda CloudWatch log group |
| `get_lambda_log_group_arn` | ARN of the get Lambda CloudWatch log group |

## Lambda Functions

### Submit Lead Function
- **Purpose**: Process POST requests from lead capture forms
- **Handler**: Configurable via `submit_lambda_handler`
- **Environment Variables**:
  - `DYNAMODB_TABLE_NAME`: Target DynamoDB table
  - `CORS_ALLOW_ORIGIN`: CORS configuration
  - `LOG_LEVEL`: Logging verbosity
  - Custom variables via `submit_lambda_environment_variables`

### Get Leads Function
- **Purpose**: Retrieve stored leads (for admin/integration use)
- **Handler**: Configurable via `get_lambda_handler`
- **Environment Variables**:
  - `DYNAMODB_TABLE_NAME`: Source DynamoDB table
  - `LOG_LEVEL`: Logging verbosity
  - Custom variables via `get_lambda_environment_variables`

## IAM Permissions

The module creates an IAM execution role with:

### Basic Permissions
- **AWSLambdaBasicExecutionRole**: CloudWatch Logs access

### DynamoDB Permissions
- `dynamodb:PutItem`: Store new leads
- `dynamodb:GetItem`: Retrieve individual leads
- `dynamodb:Query`: Query leads by attributes
- `dynamodb:Scan`: Scan table for bulk operations
- `dynamodb:UpdateItem`: Update existing leads
- `dynamodb:DeleteItem`: Remove leads (if needed)

### SES Permissions (if enabled)
- `ses:SendEmail`: Send plain text emails
- `ses:SendRawEmail`: Send HTML emails

## CloudWatch Monitoring

### Log Groups
- Automatic log group creation for each Lambda function
- Configurable retention period
- Structured logging support

### CloudWatch Alarms (if enabled)
- **Error Rate Alarms**: Trigger when error count exceeds threshold
- **Duration Alarms**: Monitor function execution time
- **Configurable Thresholds**: 5 errors in 10 minutes, 10-second duration

## Environment Variables

### Default Environment Variables
All Lambda functions receive:
- `DYNAMODB_TABLE_NAME`: DynamoDB table name
- `LOG_LEVEL`: Logging level (DEBUG, INFO, WARN, ERROR)

### Submit Lambda Additional Variables
- `CORS_ALLOW_ORIGIN`: CORS configuration for responses

### Custom Environment Variables
Add custom variables using:
- `submit_lambda_environment_variables`: For submit function
- `get_lambda_environment_variables`: For get function

Example:
```hcl
submit_lambda_environment_variables = {
  SES_FROM_EMAIL     = "noreply@example.com"
  NOTIFICATION_EMAIL = "admin@example.com"
  WEBHOOK_URL        = "https://webhook.example.com"
}
```

## Deployment Package Requirements

### ZIP File Structure
```
submit-lead.zip
├── submit-lead.js          # Main handler file
├── package.json            # Dependencies
├── node_modules/           # Dependencies (if not using layers)
└── lib/                    # Additional modules
```

### Handler Function Format
```javascript
// submit-lead.js
exports.handler = async (event, context) => {
  // Your function logic here
  return {
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': process.env.CORS_ALLOW_ORIGIN,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ success: true })
  };
};
```

## Performance Optimization

### Memory Sizing
- **128-256 MB**: Basic form processing
- **512 MB**: Complex validation or external API calls
- **1024+ MB**: Heavy processing or large payloads

### Timeout Configuration
- **15-30 seconds**: Standard form processing
- **60+ seconds**: External integrations or complex operations

### Cold Start Optimization
- Use provisioned concurrency for consistent performance
- Minimize deployment package size
- Optimize initialization code

## Security Best Practices

### IAM Roles
- Least-privilege principle applied
- Separate roles for different functions if needed
- No hardcoded credentials

### Environment Variables
- Sensitive data should be encrypted at rest
- Use AWS Systems Manager Parameter Store for secrets
- Avoid logging sensitive information

### Input Validation
- Validate all input data in Lambda functions
- Sanitize data before database operations
- Implement rate limiting at application level

## Integration with Other Modules

This module integrates with:
- **API Gateway Module**: Provides the HTTP endpoints
- **DynamoDB Module**: Stores and retrieves lead data
- **SES Module**: Sends email notifications (optional)

## Troubleshooting

### Common Issues

1. **ZIP File Not Found**: Ensure paths in variables are correct
2. **Permission Denied**: Check IAM role permissions
3. **Timeout Errors**: Increase timeout value or optimize code
4. **Memory Errors**: Increase memory allocation
5. **Cold Start Issues**: Consider provisioned concurrency

### Debugging

1. **Check CloudWatch Logs**: Function execution logs
2. **Monitor Metrics**: Error rates, duration, invocations
3. **Test Locally**: Use SAM CLI for local testing
4. **API Gateway Logs**: Enable execution logging

### Testing

Test Lambda functions directly:
```bash
# Using AWS CLI
aws lambda invoke \
  --function-name lead-capture-submit-lead \
  --payload '{"body":"{\"name\":\"Test\",\"email\":\"test@example.com\"}"}' \
  response.json
```