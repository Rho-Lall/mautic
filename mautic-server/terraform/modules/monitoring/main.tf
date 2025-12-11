# Monitoring Module - Main Configuration
# This module creates CloudWatch dashboards and alarms for Mautic deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-ecs-logs"
    Environment = var.environment
    Module      = "monitoring"
  })
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.ecs_service_name, "ClusterName", var.ecs_cluster_name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Service Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Load Balancer Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id],
            [".", "DatabaseConnections", ".", "."],
            [".", "FreeableMemory", ".", "."],
            [".", "FreeStorageSpace", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS Metrics"
          period  = 300
        }
      }
    ]
  })


}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  count = var.enable_alerts ? 1 : 0
  name  = "${var.project_name}-${var.environment}-alerts"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-alerts"
    Environment = var.environment
    Module      = "monitoring"
  })
}

# CloudWatch Alarms for ECS
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  count = var.enable_alerts ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "This metric monitors ECS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    ServiceName = var.ecs_service_name
    ClusterName = var.ecs_cluster_name
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-ecs-cpu-high"
    Environment = var.environment
    Module      = "monitoring"
  })
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  count = var.enable_alerts ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold
  alarm_description   = "This metric monitors ECS memory utilization"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    ServiceName = var.ecs_service_name
    ClusterName = var.ecs_cluster_name
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-ecs-memory-high"
    Environment = var.environment
    Module      = "monitoring"
  })
}

# CloudWatch Alarms for ALB
resource "aws_cloudwatch_metric_alarm" "alb_response_time_high" {
  count = var.enable_alerts ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = var.response_time_alarm_threshold
  alarm_description   = "This metric monitors ALB response time"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-alb-response-time-high"
    Environment = var.environment
    Module      = "monitoring"
  })
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count = var.enable_alerts ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.rds_cpu_alarm_threshold
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-rds-cpu-high"
    Environment = var.environment
    Module      = "monitoring"
  })
}