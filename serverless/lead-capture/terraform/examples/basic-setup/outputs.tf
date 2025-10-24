# Outputs for the basic lead capture setup example

output "api_gateway_url" {
  description = "URL of the API Gateway endpoint"
  value       = module.api_gateway.api_gateway_url
}

output "custom_domain_url" {
  description = "URL of the custom domain (if configured)"
  value       = module.api_gateway.custom_domain_url
}

output "api_key_value" {
  description = "API key for form authentication (if enabled)"
  value       = module.api_gateway.api_key_value
  sensitive   = true
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table storing leads"
  value       = module.dynamodb.table_name
}

output "lambda_function_names" {
  description = "Names of the deployed Lambda functions"
  value = {
    submit_lead = module.lambda.submit_lambda_function_name
    get_leads   = module.lambda.get_lambda_function_name
  }
}

output "ses_configuration" {
  description = "SES configuration details (if enabled)"
  value = var.enable_email_notifications ? {
    configuration_set_name = module.ses[0].configuration_set_name
    domain_verification_token = module.ses[0].domain_identity_verification_token
    dkim_tokens = module.ses[0].dkim_tokens
    sns_topic_arn = module.ses[0].sns_topic_arn
  } : null
}

output "form_integration_example" {
  description = "Example HTML code for embedding the lead capture form"
  value = <<-EOT
    <!-- Lead Capture Form Integration -->
    <script src="https://your-cdn.com/lead-capture.js"></script>
    <div id="lead-capture-form" 
         data-api-endpoint="${module.api_gateway.custom_domain_url != "" ? module.api_gateway.custom_domain_url : module.api_gateway.api_gateway_url}/leads"
         data-api-key="${var.enable_api_key ? "YOUR_API_KEY_HERE" : ""}"
         data-fields="name,email,company">
    </div>
  EOT
}