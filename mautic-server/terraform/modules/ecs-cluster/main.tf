# ECS Cluster Module - Main Configuration
# This module creates an ECS Fargate cluster for Mautic deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cluster"
    Environment = var.environment
    Module      = "ecs-cluster"
  })
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = var.fargate_base_capacity
    weight            = var.fargate_weight
    capacity_provider = "FARGATE"
  }

  dynamic "default_capacity_provider_strategy" {
    for_each = var.enable_fargate_spot ? [1] : []
    content {
      base              = var.fargate_spot_base_capacity
      weight            = var.fargate_spot_weight
      capacity_provider = "FARGATE_SPOT"
    }
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  count = var.create_service ? 1 : 0

  family                   = "${var.project_name}-${var.environment}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = var.environment_variables

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-${var.environment}"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = var.enable_health_check ? {
        command     = var.health_check_command
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_retries
        startPeriod = var.health_check_start_period
      } : null
    }
  ])

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-task"
    Environment = var.environment
    Module      = "ecs-cluster"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  count = var.create_service ? 1 : 0

  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-logs"
    Environment = var.environment
    Module      = "ecs-cluster"
  })
}

# ECS Service
resource "aws_ecs_service" "main" {
  count = var.create_service ? 1 : 0

  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main[0].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  health_check_grace_period_seconds = var.target_group_arn != null ? var.health_check_grace_period : null

  # Note: deployment_configuration block may not be supported in this provider version
  # Users can configure deployment settings through AWS console or CLI if needed

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-service"
    Environment = var.environment
    Module      = "ecs-cluster"
  })

  depends_on = [aws_cloudwatch_log_group.main]
}

# Application Auto Scaling Target
resource "aws_appautoscaling_target" "main" {
  count = var.create_service && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-autoscaling-target"
    Environment = var.environment
    Module      = "ecs-cluster"
  })
}

# Auto Scaling Policy - CPU
resource "aws_appautoscaling_policy" "cpu" {
  count = var.create_service && var.enable_autoscaling && var.enable_cpu_scaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main[0].resource_id
  scalable_dimension = aws_appautoscaling_target.main[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.main[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}

# Auto Scaling Policy - Memory
resource "aws_appautoscaling_policy" "memory" {
  count = var.create_service && var.enable_autoscaling && var.enable_memory_scaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main[0].resource_id
  scalable_dimension = aws_appautoscaling_target.main[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.main[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.memory_target_value
  }
}

# Data source for current AWS region
data "aws_region" "current" {}