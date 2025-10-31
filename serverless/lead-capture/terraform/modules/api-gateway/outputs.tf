output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.lead_capture_api.id
}

output "api_gateway_arn" {
  description = "ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.lead_capture_api.arn
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.lead_capture_api.execution_arn
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.lead_capture_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.stage_name}"
}

output "custom_domain_url" {
  description = "URL of the custom domain (if configured)"
  value       = var.custom_domain_name != "" ? "https://${var.custom_domain_name}" : ""
}

output "api_key_id" {
  description = "ID of the API key (if enabled)"
  value       = var.enable_api_key ? aws_api_gateway_api_key.lead_capture_key[0].id : ""
}

output "api_key_value" {
  description = "Value of the API key (if enabled)"
  value       = var.enable_api_key ? aws_api_gateway_api_key.lead_capture_key[0].value : ""
  sensitive   = true
}

output "usage_plan_id" {
  description = "ID of the usage plan (if API key is enabled)"
  value       = var.enable_api_key ? aws_api_gateway_usage_plan.lead_capture_plan[0].id : ""
}

output "stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.lead_capture_stage.stage_name
}

output "leads_resource_id" {
  description = "ID of the leads resource"
  value       = aws_api_gateway_resource.leads.id
}

# Custom Domain Outputs
output "custom_domain_name" {
  description = "Custom domain name (if configured)"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.lead_capture_domain[0].domain_name : ""
}

output "custom_domain_regional_domain_name" {
  description = "Regional domain name for custom domain (if configured)"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.lead_capture_domain[0].regional_domain_name : ""
}

output "custom_domain_regional_zone_id" {
  description = "Regional zone ID for custom domain (if configured)"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.lead_capture_domain[0].regional_zone_id : ""
}

# Data source for current AWS region
data "aws_region" "current" {}