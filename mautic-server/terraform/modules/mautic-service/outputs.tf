# Mautic Service Module - Outputs
# Standard output pattern for module interconnection

output "service_id" {
  description = "ECS service identifier"
  value       = aws_ecs_service.mautic.id
}

output "service_arn" {
  description = "ECS service ARN for cross-module references"
  value       = aws_ecs_service.mautic.id
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.mautic.name
}

output "task_definition_arn" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.mautic.arn
}

output "task_definition_family" {
  description = "ECS task definition family"
  value       = aws_ecs_task_definition.mautic.family
}

output "task_definition_revision" {
  description = "ECS task definition revision"
  value       = aws_ecs_task_definition.mautic.revision
}

output "execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.ecs_task_role.arn
}

output "connection_info" {
  description = "Connection details for other modules"
  value = {
    service_name           = aws_ecs_service.mautic.name
    task_definition_arn    = aws_ecs_task_definition.mautic.arn
    execution_role_arn     = aws_iam_role.ecs_execution_role.arn
    task_role_arn         = aws_iam_role.ecs_task_role.arn
  }
}

# Auto Scaling Outputs
output "autoscaling_target_resource_id" {
  description = "Auto scaling target resource ID"
  value       = var.enable_autoscaling ? aws_appautoscaling_target.mautic[0].resource_id : null
}

output "cpu_scaling_policy_arn" {
  description = "CPU scaling policy ARN"
  value       = var.enable_autoscaling && var.enable_cpu_scaling ? aws_appautoscaling_policy.cpu[0].arn : null
}

output "memory_scaling_policy_arn" {
  description = "Memory scaling policy ARN"
  value       = var.enable_autoscaling && var.enable_memory_scaling ? aws_appautoscaling_policy.memory[0].arn : null
}