# API Gateway REST API
resource "aws_api_gateway_rest_api" "lead_capture_api" {
  name        = var.api_name
  description = var.api_description

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "lead_capture_deployment" {
  depends_on = [
    aws_api_gateway_method.leads_post,
    aws_api_gateway_method.leads_get,
    aws_api_gateway_method.leads_options,
    aws_api_gateway_integration.leads_post_integration,
    aws_api_gateway_integration.leads_get_integration,
    aws_api_gateway_integration.leads_options_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.lead_capture_api.id
  stage_name  = var.stage_name

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "lead_capture_stage" {
  deployment_id = aws_api_gateway_deployment.lead_capture_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.lead_capture_api.id
  stage_name    = var.stage_name

  tags = var.tags
}

# Leads Resource
resource "aws_api_gateway_resource" "leads" {
  rest_api_id = aws_api_gateway_rest_api.lead_capture_api.id
  parent_id   = aws_api_gateway_rest_api.lead_capture_api.root_resource_id
  path_part   = "leads"
}

# POST Method for lead submission
resource "aws_api_gateway_method" "leads_post" {
  rest_api_id   = aws_api_gateway_rest_api.lead_capture_api.id
  resource_id   = aws_api_gateway_resource.leads.id
  http_method   = "POST"
  authorization = var.enable_api_key ? "NONE" : "NONE"
  api_key_required = var.enable_api_key

  request_validator_id = aws_api_gateway_request_validator.lead_capture_validator.id
}

# GET Method for lead retrieval
resource "aws_api_gateway_method" "leads_get" {
  rest_api_id   = aws_api_gateway_rest_api.lead_capture_api.id
  resource_id   = aws_api_gateway_resource.leads.id
  http_method   = "GET"
  authorization = "AWS_IAM"
}

# OPTIONS Method for CORS preflight
resource "aws_api_gateway_method" "leads_options" {
  rest_api_id   = aws_api_gateway_rest_api.lead_capture_api.id
  resource_id   = aws_api_gateway_resource.leads.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Request Validator
resource "aws_api_gateway_request_validator" "lead_capture_validator" {
  name                        = "${var.api_name}-validator"
  rest_api_id                 = aws_api_gateway_rest_api.lead_capture_api.id
  validate_request_body       = true
  validate_request_parameters = true
}

# Lambda Integration for POST
resource "aws_api_gateway_integration" "leads_post_integration" {
  rest_api_id = aws_api_gateway_rest_api.lead_capture_api.id
  resource_id = aws_api_gateway_resource.leads.id
  http_method = aws_api_gateway_method.leads_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = var.submit_lambda_invoke_arn
}

# Lambda Integration for GET
resource "aws_api_gateway_integration" "leads_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.lead_capture_api.id
  resource_id = aws_api_gateway_resource.leads.id
  http_method = aws_api_gateway_method.leads_get.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = var.get_lambda_invoke_arn
}

# CORS Integration for OPTIONS
resource "aws_api_gateway_integration" "leads_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.lead_capture_api.id
  resource_id = aws_api_gateway_resource.leads.id
  http_method = aws_api_gateway_method.leads_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# CORS Method Response for OPTIONS
resource "aws_api_gateway_method_response" "leads_options_response" {
  rest_api_id = aws_api_gateway_rest_api.lead_capture_api.id
  resource_id = aws_api_gateway_resource.leads.id
  http_method = aws_api_gateway_method.leads_options.http_method
  status_code = "200"

  response_headers = {
    "Access-Control-Allow-Headers" = true
    "Access-Control-Allow-Methods" = true
    "Access-Control-Allow-Origin"  = true
  }
}

# CORS Integration Response for OPTIONS
resource "aws_api_gateway_integration_response" "leads_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.lead_capture_api.id
  resource_id = aws_api_gateway_resource.leads.id
  http_method = aws_api_gateway_method.leads_options.http_method
  status_code = aws_api_gateway_method_response.leads_options_response.status_code

  response_headers = {
    "Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "Access-Control-Allow-Origin"  = var.cors_allow_origin
  }
}

# Method Response for POST
resource "aws_api_gateway_method_response" "leads_post_response" {
  rest_api_id = aws_api_gateway_rest_api.lead_capture_api.id
  resource_id = aws_api_gateway_resource.leads.id
  http_method = aws_api_gateway_method.leads_post.http_method
  status_code = "200"

  response_headers = {
    "Access-Control-Allow-Origin" = true
  }
}

# Method Response for GET
resource "aws_api_gateway_method_response" "leads_get_response" {
  rest_api_id = aws_api_gateway_rest_api.lead_capture_api.id
  resource_id = aws_api_gateway_resource.leads.id
  http_method = aws_api_gateway_method.leads_get.http_method
  status_code = "200"

  response_headers = {
    "Access-Control-Allow-Origin" = true
  }
}
# Custom D
omain (optional)
resource "aws_api_gateway_domain_name" "lead_capture_domain" {
  count           = var.custom_domain_name != "" ? 1 : 0
  domain_name     = var.custom_domain_name
  certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# Base Path Mapping for Custom Domain
resource "aws_api_gateway_base_path_mapping" "lead_capture_mapping" {
  count       = var.custom_domain_name != "" ? 1 : 0
  api_id      = aws_api_gateway_rest_api.lead_capture_api.id
  stage_name  = aws_api_gateway_stage.lead_capture_stage.stage_name
  domain_name = aws_api_gateway_domain_name.lead_capture_domain[0].domain_name
}

# API Key (optional)
resource "aws_api_gateway_api_key" "lead_capture_key" {
  count = var.enable_api_key ? 1 : 0
  name  = "${var.api_name}-key"

  tags = var.tags
}

# Usage Plan
resource "aws_api_gateway_usage_plan" "lead_capture_plan" {
  count = var.enable_api_key ? 1 : 0
  name  = "${var.api_name}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.lead_capture_api.id
    stage  = aws_api_gateway_stage.lead_capture_stage.stage_name
  }

  quota_settings {
    limit  = var.quota_limit
    period = var.quota_period
  }

  throttle_settings {
    rate_limit  = var.throttle_rate_limit
    burst_limit = var.throttle_burst_limit
  }

  tags = var.tags
}

# Usage Plan Key
resource "aws_api_gateway_usage_plan_key" "lead_capture_plan_key" {
  count         = var.enable_api_key ? 1 : 0
  key_id        = aws_api_gateway_api_key.lead_capture_key[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.lead_capture_plan[0].id
}

# Lambda Permissions
resource "aws_lambda_permission" "api_gateway_submit_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.submit_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lead_capture_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_get_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.get_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lead_capture_api.execution_arn}/*/*"
}