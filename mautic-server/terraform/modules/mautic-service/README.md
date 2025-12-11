# Mautic Service Module

This module creates a Mautic-specific ECS service with task definition, IAM roles, and service configuration for running Mautic in AWS Fargate.

## Features

- ECS Fargate task definition for Mautic container
- ECS service with load balancer integration
- IAM roles with least-privilege permissions
- Secrets Manager integration for sensitive data
- Health checks and logging configuration
- Configurable resource allocation
- Auto-scaling capabilities with CPU and memory metrics
- Flexible environment variable configuration
- Mautic-specific configuration options

## Usage

```hcl
module "mautic_service" {
  source = "./modules/mautic-service"

  project_name = "my-project"
  environment  = "dev"
  aws_region   = "us-east-1"
  
  # ECS Configuration
  ecs_cluster_id        = module.ecs_cluster.cluster_id
  ecs_cluster_name      = module.ecs_cluster.cluster_name
  private_subnet_ids    = module.networking.private_subnet_ids
  ecs_security_group_id = module.networking.ecs_tasks_security_group_id
  target_group_arn      = module.load_balancer.target_group_arn
  log_group_name        = module.monitoring.log_group_name
  
  # Task Configuration
  task_cpu      = 512
  task_memory   = 1024
  desired_count = 2
  
  # Mautic Configuration
  database_host                 = module.database.db_instance_endpoint
  database_name                 = "mautic"
  database_user                 = "mautic_admin"
  database_password_secret_arn  = aws_secretsmanager_secret.db_password.arn
  secret_key_secret_arn        = aws_secretsmanager_secret.mautic_key.arn
  trusted_hosts                = "example.com,www.example.com"
  
  # Auto Scaling Configuration
  enable_autoscaling      = true
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 5
  enable_cpu_scaling      = true
  cpu_target_value        = 70
  
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

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| project_name | Project name for resource naming | `string` | n/a | yes |
| ecs_cluster_id | ECS cluster ID where the service will be deployed | `string` | n/a | yes |
| ecs_cluster_name | ECS cluster name for auto-scaling configuration | `string` | n/a | yes |
| private_subnet_ids | List of private subnet IDs for ECS service | `list(string)` | n/a | yes |
| ecs_security_group_id | Security group ID for ECS tasks | `string` | n/a | yes |
| target_group_arn | Target group ARN for load balancer integration | `string` | n/a | yes |
| log_group_name | CloudWatch log group name for container logs | `string` | n/a | yes |
| database_host | Database host endpoint | `string` | n/a | yes |
| database_password_secret_arn | ARN of the secret containing the database password | `string` | n/a | yes |
| secret_key_secret_arn | ARN of the secret containing the Mautic secret key | `string` | n/a | yes |
| tags | Common tags for all resources | `map(string)` | `{}` | no |
| task_cpu | CPU units for the ECS task | `number` | `512` | no |
| task_memory | Memory (MB) for the ECS task | `number` | `1024` | no |
| desired_count | Desired number of ECS service instances | `number` | `1` | no |
| mautic_image | Mautic Docker image to use | `string` | `"mautic/mautic:latest"` | no |
| database_name | Database name | `string` | `"mautic"` | no |
| database_user | Database username | `string` | `"mautic_admin"` | no |
| trusted_hosts | Comma-separated list of trusted hosts for Mautic | `string` | `""` | no |
| enable_cron_jobs | Enable Mautic cron jobs in the container | `bool` | `true` | no |
| additional_environment_variables | Additional environment variables for the Mautic container | `list(object)` | `[]` | no |
| enable_autoscaling | Enable auto scaling for the Mautic service | `bool` | `false` | no |
| autoscaling_min_capacity | Minimum number of tasks for auto scaling | `number` | `1` | no |
| autoscaling_max_capacity | Maximum number of tasks for auto scaling | `number` | `10` | no |
| enable_cpu_scaling | Enable CPU-based auto scaling | `bool` | `true` | no |
| cpu_target_value | Target CPU utilization percentage for auto scaling | `number` | `70` | no |
| enable_memory_scaling | Enable memory-based auto scaling | `bool` | `false` | no |
| memory_target_value | Target memory utilization percentage for auto scaling | `number` | `80` | no |

## Outputs

| Name | Description |
|------|-------------|
| service_id | ECS service identifier |
| service_arn | ECS service ARN for cross-module references |
| service_name | ECS service name |
| task_definition_arn | ECS task definition ARN |
| execution_role_arn | ECS task execution role ARN |
| task_role_arn | ECS task role ARN |
| connection_info | Connection details for other modules |
| autoscaling_target_resource_id | Auto scaling target resource ID |
| cpu_scaling_policy_arn | CPU scaling policy ARN |
| memory_scaling_policy_arn | Memory scaling policy ARN |