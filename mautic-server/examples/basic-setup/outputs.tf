# Outputs for Basic Mautic Deployment Example

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.load_balancer.load_balancer_dns_name
}

output "load_balancer_zone_id" {
  description = "Hosted zone ID of the load balancer"
  value       = module.load_balancer.load_balancer_zone_id
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_instance_endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.mautic_service.service_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = module.monitoring.dashboard_url
}

output "mautic_url" {
  description = "URL to access Mautic application"
  value       = var.ssl_certificate_arn != null ? "https://${module.load_balancer.load_balancer_dns_name}" : "http://${module.load_balancer.load_balancer_dns_name}"
}