# Monitoring Module - Outputs
# Standard output pattern for module interconnection

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN for cross-module references"
  value       = aws_cloudwatch_log_group.ecs.arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = var.enable_alerts ? aws_sns_topic.alerts[0].arn : null
}

output "alarm_names" {
  description = "List of CloudWatch alarm names"
  value = var.enable_alerts ? [
    aws_cloudwatch_metric_alarm.ecs_cpu_high[0].alarm_name,
    aws_cloudwatch_metric_alarm.ecs_memory_high[0].alarm_name,
    aws_cloudwatch_metric_alarm.alb_response_time_high[0].alarm_name,
    aws_cloudwatch_metric_alarm.rds_cpu_high[0].alarm_name
  ] : []
}

output "connection_info" {
  description = "Connection details for other modules"
  value = {
    log_group_name = aws_cloudwatch_log_group.ecs.name
    log_group_arn  = aws_cloudwatch_log_group.ecs.arn
    sns_topic_arn  = var.enable_alerts ? aws_sns_topic.alerts[0].arn : null
  }
}