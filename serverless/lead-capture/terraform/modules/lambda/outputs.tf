output "submit_lambda_function_name" {
  description = "Name of the submit lead Lambda function"
  value       = aws_lambda_function.submit_lead.function_name
}

output "submit_lambda_function_arn" {
  description = "ARN of the submit lead Lambda function"
  value       = aws_lambda_function.submit_lead.arn
}

output "submit_lambda_invoke_arn" {
  description = "Invoke ARN of the submit lead Lambda function"
  value       = aws_lambda_function.submit_lead.invoke_arn
}

output "get_lambda_function_name" {
  description = "Name of the get leads Lambda function"
  value       = aws_lambda_function.get_leads.function_name
}

output "get_lambda_function_arn" {
  description = "ARN of the get leads Lambda function"
  value       = aws_lambda_function.get_leads.arn
}

output "get_lambda_invoke_arn" {
  description = "Invoke ARN of the get leads Lambda function"
  value       = aws_lambda_function.get_leads.invoke_arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.name
}

output "submit_lambda_log_group_name" {
  description = "Name of the submit Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.submit_lambda_logs.name
}

output "get_lambda_log_group_name" {
  description = "Name of the get Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.get_lambda_logs.name
}

output "submit_lambda_log_group_arn" {
  description = "ARN of the submit Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.submit_lambda_logs.arn
}

output "get_lambda_log_group_arn" {
  description = "ARN of the get Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.get_lambda_logs.arn
}