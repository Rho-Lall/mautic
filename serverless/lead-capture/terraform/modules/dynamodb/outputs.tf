output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.leads_table.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.leads_table.arn
}

output "table_id" {
  description = "ID of the DynamoDB table"
  value       = aws_dynamodb_table.leads_table.id
}

output "table_stream_arn" {
  description = "ARN of the DynamoDB table stream (if enabled)"
  value       = var.enable_streams ? aws_dynamodb_table.leads_table.stream_arn : ""
}

output "table_stream_label" {
  description = "Label of the DynamoDB table stream (if enabled)"
  value       = var.enable_streams ? aws_dynamodb_table.leads_table.stream_label : ""
}

output "kms_key_id" {
  description = "ID of the KMS key used for encryption (if enabled)"
  value       = var.enable_encryption ? aws_kms_key.dynamodb_key[0].key_id : ""
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption (if enabled)"
  value       = var.enable_encryption ? aws_kms_key.dynamodb_key[0].arn : ""
}

output "kms_key_alias" {
  description = "Alias of the KMS key used for encryption (if enabled)"
  value       = var.enable_encryption ? aws_kms_alias.dynamodb_key_alias[0].name : ""
}

output "email_gsi_name" {
  description = "Name of the email Global Secondary Index"
  value       = "email-index"
}

output "source_gsi_name" {
  description = "Name of the source Global Secondary Index"
  value       = "source-index"
}

output "hash_key" {
  description = "Hash key of the DynamoDB table"
  value       = var.hash_key
}

output "range_key" {
  description = "Range key of the DynamoDB table"
  value       = var.range_key
}

output "billing_mode" {
  description = "Billing mode of the DynamoDB table"
  value       = var.billing_mode
}

output "point_in_time_recovery_enabled" {
  description = "Whether point-in-time recovery is enabled"
  value       = var.enable_point_in_time_recovery
}

output "encryption_enabled" {
  description = "Whether encryption at rest is enabled"
  value       = var.enable_encryption
}

output "streams_enabled" {
  description = "Whether DynamoDB streams are enabled"
  value       = var.enable_streams
}

output "ttl_enabled" {
  description = "Whether TTL is enabled"
  value       = var.enable_ttl
}

output "ttl_attribute" {
  description = "TTL attribute name"
  value       = var.ttl_attribute
}