# Database Module - Outputs
# Standard output pattern for module interconnection

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "RDS instance ARN for cross-module references"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_instance_address" {
  description = "RDS instance hostname"
  value       = aws_db_instance.main.address
}

output "db_subnet_group_id" {
  description = "DB subnet group identifier"
  value       = aws_db_subnet_group.main.id
}

output "db_parameter_group_id" {
  description = "DB parameter group identifier"
  value       = aws_db_parameter_group.main.id
}

output "connection_info" {
  description = "Connection details for other modules"
  value = {
    endpoint = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    address  = aws_db_instance.main.address
  }
  sensitive = true
}

output "database_credentials" {
  description = "Database connection credentials"
  value = {
    database_name = aws_db_instance.main.db_name
    username      = aws_db_instance.main.username
  }
  sensitive = true
}