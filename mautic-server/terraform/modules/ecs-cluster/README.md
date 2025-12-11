# ECS Cluster Module

This module creates an Amazon ECS Fargate cluster with optional ECS service, task definition, and auto-scaling capabilities for running containerized applications.

## Features

- ECS Fargate cluster with configurable capacity providers
- Optional ECS service with task definition
- Configurable container resources (CPU, memory)
- Container health checks
- Auto-scaling based on CPU and memory utilization
- CloudWatch logging integration
- Load balancer integration support
- Optional CloudWatch Container Insights
- Support for Fargate and Fargate Spot capacity providers
- Consistent tagging and naming conventions

## Usage

### Basic Cluster Only

```hcl
module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  project_name = "my-project"
  environment  = "dev"
  
  enable_container_insights = true
  enable_fargate_spot      = true
  
  tags = {
    Owner = "DevOps Team"
    Cost  = "Development"
  }
}
```

### Cluster with ECS Service

```hcl
module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  project_name = "my-project"
  environment  = "dev"
  
  # Service Configuration
  create_service    = true
  container_name    = "mautic"
  container_image   = "mautic/mautic:latest"
  container_port    = 80
  task_cpu          = 512
  task_memory       = 1024
  desired_count     = 2
  
  # Network Configuration
  subnet_ids         = ["subnet-12345", "subnet-67890"]
  security_group_ids = ["sg-12345"]
  assign_public_ip   = false
  
  # Load Balancer Integration
  target_group_arn = "arn:aws:elasticloadbalancing:..."
  
  # Auto Scaling
  enable_autoscaling      = true
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 5
  enable_cpu_scaling      = true
  cpu_target_value        = 70
  
  # Health Checks
  enable_health_check = true
  health_check_command = ["CMD-SHELL", "curl -f http://localhost/health || exit 1"]
  
  # Environment Variables
  environment_variables = [
    {
      name  = "MAUTIC_DB_HOST"
      value = "placeholder-db-host"
    },
    {
      name  = "MAUTIC_DB_NAME"
      value = "placeholder-db-name"
    }
  ]
  
  tags = {
    Owner = "DevOps Team"
    Cost  = "Development"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

### Core Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| project_name | Project name for resource naming | `string` | n/a | yes |
| tags | Common tags for all resources | `map(string)` | `{}` | no |

### Cluster Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_container_insights | Enable CloudWatch Container Insights for the cluster | `bool` | `true` | no |
| fargate_base_capacity | Base capacity for Fargate capacity provider | `number` | `1` | no |
| fargate_weight | Weight for Fargate capacity provider | `number` | `1` | no |
| enable_fargate_spot | Enable Fargate Spot capacity provider | `bool` | `false` | no |
| fargate_spot_base_capacity | Base capacity for Fargate Spot capacity provider | `number` | `0` | no |
| fargate_spot_weight | Weight for Fargate Spot capacity provider | `number` | `1` | no |

### Service Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_service | Whether to create ECS service and related resources | `bool` | `false` | no |
| container_name | Name of the container | `string` | `"app"` | no |
| container_image | Docker image for the container | `string` | `"nginx:latest"` | no |
| container_port | Port exposed by the container | `number` | `80` | no |
| task_cpu | CPU units for the task (256, 512, 1024, 2048, 4096) | `number` | `256` | no |
| task_memory | Memory (MB) for the task | `number` | `512` | no |
| execution_role_arn | ARN of the task execution role | `string` | `null` | no |
| task_role_arn | ARN of the task role | `string` | `null` | no |
| environment_variables | Environment variables for the container | `list(object)` | `[]` | no |
| desired_count | Desired number of tasks | `number` | `1` | no |
| subnet_ids | List of subnet IDs for the service | `list(string)` | `[]` | no |
| security_group_ids | List of security group IDs for the service | `list(string)` | `[]` | no |
| assign_public_ip | Whether to assign a public IP to the task | `bool` | `false` | no |
| target_group_arn | ARN of the target group for load balancer integration | `string` | `null` | no |

### Health Check Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_health_check | Enable container health check | `bool` | `true` | no |
| health_check_command | Health check command | `list(string)` | `["CMD-SHELL", "curl -f http://localhost/ \|\| exit 1"]` | no |
| health_check_interval | Health check interval in seconds | `number` | `30` | no |
| health_check_timeout | Health check timeout in seconds | `number` | `5` | no |
| health_check_retries | Number of health check retries | `number` | `3` | no |
| health_check_start_period | Health check start period in seconds | `number` | `60` | no |
| health_check_grace_period | Health check grace period in seconds | `number` | `300` | no |

### Auto Scaling Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_autoscaling | Enable auto scaling for the service | `bool` | `false` | no |
| autoscaling_min_capacity | Minimum number of tasks for auto scaling | `number` | `1` | no |
| autoscaling_max_capacity | Maximum number of tasks for auto scaling | `number` | `10` | no |
| enable_cpu_scaling | Enable CPU-based auto scaling | `bool` | `true` | no |
| cpu_target_value | Target CPU utilization percentage for auto scaling | `number` | `70` | no |
| enable_memory_scaling | Enable memory-based auto scaling | `bool` | `false` | no |
| memory_target_value | Target memory utilization percentage for auto scaling | `number` | `80` | no |

### Logging Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| log_retention_days | CloudWatch log retention in days | `number` | `7` | no |

## Outputs

### Cluster Outputs

| Name | Description |
|------|-------------|
| cluster_id | ECS cluster identifier |
| cluster_arn | ECS cluster ARN for cross-module references |
| cluster_name | ECS cluster name |
| cluster_capacity_providers | List of capacity providers associated with the cluster |
| connection_info | Connection details for other modules |

### Service Outputs

| Name | Description |
|------|-------------|
| service_id | ECS service identifier |
| service_name | ECS service name |
| service_arn | ECS service ARN |
| task_definition_arn | ECS task definition ARN |
| task_definition_family | ECS task definition family |
| log_group_name | CloudWatch log group name |
| log_group_arn | CloudWatch log group ARN |

### Auto Scaling Outputs

| Name | Description |
|------|-------------|
| autoscaling_target_resource_id | Auto scaling target resource ID |
| cpu_scaling_policy_arn | CPU scaling policy ARN |
| memory_scaling_policy_arn | Memory scaling policy ARN |