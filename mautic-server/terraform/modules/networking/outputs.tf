# Networking Module - Outputs
# Standard output pattern for module interconnection

output "vpc_id" {
  description = "VPC identifier"
  value       = var.create_resources ? aws_vpc.main[0].id : null
}

output "vpc_arn" {
  description = "VPC ARN for cross-module references"
  value       = var.create_resources ? aws_vpc.main[0].arn : null
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = var.create_resources ? aws_vpc.main[0].cidr_block : var.vpc_cidr
}

output "internet_gateway_id" {
  description = "Internet Gateway identifier"
  value       = var.create_resources ? aws_internet_gateway.main[0].id : null
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public IPs associated with NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
  value       = var.create_resources ? aws_security_group.alb[0].id : null
}

output "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = var.create_resources ? aws_security_group.ecs_tasks[0].id : null
}

output "rds_security_group_id" {
  description = "Security group ID for RDS database"
  value       = var.create_resources ? aws_security_group.rds[0].id : null
}

output "connection_info" {
  description = "Connection details for other modules"
  value = var.create_resources ? {
    vpc_id                       = aws_vpc.main[0].id
    public_subnet_ids            = aws_subnet.public[*].id
    private_subnet_ids           = aws_subnet.private[*].id
    alb_security_group_id        = aws_security_group.alb[0].id
    ecs_tasks_security_group_id  = aws_security_group.ecs_tasks[0].id
    rds_security_group_id        = aws_security_group.rds[0].id
  } : {
    vpc_id                       = null
    public_subnet_ids            = []
    private_subnet_ids           = []
    alb_security_group_id        = null
    ecs_tasks_security_group_id  = null
    rds_security_group_id        = null
  }
}