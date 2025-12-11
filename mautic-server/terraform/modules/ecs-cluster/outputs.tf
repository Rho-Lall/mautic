# ECS Cluster Module - Outputs
# Standard output pattern for module interconnection

output "cluster_id" {
  description = "ECS cluster identifier"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ECS cluster ARN for cross-module references"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "cluster_capacity_providers" {
  description = "List of capacity providers associated with the cluster"
  value       = aws_ecs_cluster_capacity_providers.main.capacity_providers
}

output "connection_info" {
  description = "Connection details for other modules"
  value = {
    cluster_name = aws_ecs_cluster.main.name
    cluster_arn  = aws_ecs_cluster.main.arn
  }
}

# ECS Service Outputs
output "service_id" {
  description = "ECS service identifier"
  value       = var.create_service ? aws_ecs_service.main[0].id : null
}

output "service_name" {
  description = "ECS service name"
  value       = var.create_service ? aws_ecs_service.main[0].name : null
}

output "service_arn" {
  description = "ECS service ARN"
  value       = var.create_service ? aws_ecs_service.main[0].id : null
}

output "task_definition_arn" {
  description = "ECS task definition ARN"
  value       = var.create_service ? aws_ecs_task_definition.main[0].arn : null
}

output "task_definition_family" {
  description = "ECS task definition family"
  value       = var.create_service ? aws_ecs_task_definition.main[0].family : null
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = var.create_service ? aws_cloudwatch_log_group.main[0].name : null
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = var.create_service ? aws_cloudwatch_log_group.main[0].arn : null
}

# Auto Scaling Outputs
output "autoscaling_target_resource_id" {
  description = "Auto scaling target resource ID"
  value       = var.create_service && var.enable_autoscaling ? aws_appautoscaling_target.main[0].resource_id : null
}

output "cpu_scaling_policy_arn" {
  description = "CPU scaling policy ARN"
  value       = var.create_service && var.enable_autoscaling && var.enable_cpu_scaling ? aws_appautoscaling_policy.cpu[0].arn : null
}

output "memory_scaling_policy_arn" {
  description = "Memory scaling policy ARN"
  value       = var.create_service && var.enable_autoscaling && var.enable_memory_scaling ? aws_appautoscaling_policy.memory[0].arn : null
}