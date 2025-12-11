# Mautic Service Module - Main Configuration
# This module creates a Mautic-specific ECS service configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "mautic" {
  family                   = "${var.project_name}-${var.environment}-mautic"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "mautic"
      image = var.mautic_image
      
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = concat([
        {
          name  = "MAUTIC_DB_HOST"
          value = var.database_host
        },
        {
          name  = "MAUTIC_DB_PORT"
          value = tostring(var.database_port)
        },
        {
          name  = "MAUTIC_DB_NAME"
          value = var.database_name
        },
        {
          name  = "MAUTIC_DB_USER"
          value = var.database_user
        },
        {
          name  = "MAUTIC_TRUSTED_HOSTS"
          value = var.trusted_hosts
        },
        {
          name  = "MAUTIC_RUN_CRON_JOBS"
          value = tostring(var.enable_cron_jobs)
        }
      ], var.additional_environment_variables)

      secrets = [
        {
          name      = "MAUTIC_DB_PASSWORD"
          valueFrom = var.database_password_secret_arn
        },
        {
          name      = "MAUTIC_SECRET_KEY"
          valueFrom = var.secret_key_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "mautic"
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:${var.container_port}/health || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      essential = true
    }
  ])

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-mautic-task"
    Environment = var.environment
    Module      = "mautic-service"
  })
}

# ECS Service
resource "aws_ecs_service" "mautic" {
  name            = "${var.project_name}-${var.environment}-mautic-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.mautic.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "mautic"
    container_port   = var.container_port
  }

  # Note: deployment_configuration block may not be supported in this provider version
  # Users can configure deployment settings through AWS console or CLI if needed

  enable_execute_command = var.enable_execute_command

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_role_policy,
    aws_iam_role_policy_attachment.ecs_task_role_policy
  ]

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-mautic-service"
    Environment = var.environment
    Module      = "mautic-service"
  })
}

# Application Auto Scaling Target
resource "aws_appautoscaling_target" "mautic" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.mautic.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-mautic-autoscaling-target"
    Environment = var.environment
    Module      = "mautic-service"
  })
}

# Auto Scaling Policy - CPU
resource "aws_appautoscaling_policy" "cpu" {
  count = var.enable_autoscaling && var.enable_cpu_scaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-mautic-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.mautic[0].resource_id
  scalable_dimension = aws_appautoscaling_target.mautic[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.mautic[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}

# Auto Scaling Policy - Memory
resource "aws_appautoscaling_policy" "memory" {
  count = var.enable_autoscaling && var.enable_memory_scaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-mautic-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.mautic[0].resource_id
  scalable_dimension = aws_appautoscaling_target.mautic[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.mautic[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.memory_target_value
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-ecs-execution-role"
    Environment = var.environment
    Module      = "mautic-service"
  })
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-ecs-task-role"
    Environment = var.environment
    Module      = "mautic-service"
  })
}

# IAM Policy Attachment for ECS Execution Role
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Policy for Secrets Manager Access
resource "aws_iam_role_policy" "secrets_policy" {
  name = "${var.project_name}-${var.environment}-secrets-policy"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.database_password_secret_arn,
          var.secret_key_secret_arn
        ]
      }
    ]
  })
}

# IAM Policy Attachment for ECS Task Role (minimal permissions)
resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}