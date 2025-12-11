# Monitoring Module

This module creates CloudWatch dashboards, log groups, and alarms for monitoring Mautic deployment infrastructure.

## Features

- CloudWatch log group for ECS container logs
- Comprehensive dashboard with ECS, ALB, and RDS metrics
- Configurable CloudWatch alarms for key metrics
- SNS topic for alert notifications
- Customizable alarm thresholds

## Usage

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  project_name = "my-project"
  environment  = "dev"
  aws_region   = "us-east-1"
  
  # Resource references for monitoring
  ecs_cluster_name = module.ecs_cluster.cluster_name
  ecs_service_name = "mautic-service"
  alb_arn_suffix   = module.load_balancer.load_balancer_arn
  rds_instance_id  = module.database.db_instance_id
  
  # Alert configuration
  enable_alerts = true
  cpu_alarm_threshold = 80
  memory_alarm_threshold = 80
  
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
| tags | Common tags for all resources | `map(string)` | `{}` | no |
| aws_region | AWS region for CloudWatch dashboard | `string` | `"us-east-1"` | no |
| log_retention_days | CloudWatch log retention period in days | `number` | `7` | no |
| ecs_cluster_name | Name of the ECS cluster for monitoring | `string` | `""` | no |
| ecs_service_name | Name of the ECS service for monitoring | `string` | `""` | no |
| alb_arn_suffix | ARN suffix of the Application Load Balancer for monitoring | `string` | `""` | no |
| rds_instance_id | RDS instance identifier for monitoring | `string` | `""` | no |
| enable_alerts | Enable CloudWatch alarms and SNS notifications | `bool` | `false` | no |
| cpu_alarm_threshold | CPU utilization threshold for ECS alarms (percentage) | `number` | `80` | no |
| memory_alarm_threshold | Memory utilization threshold for ECS alarms (percentage) | `number` | `80` | no |
| response_time_alarm_threshold | Response time threshold for ALB alarms (seconds) | `number` | `2` | no |
| rds_cpu_alarm_threshold | CPU utilization threshold for RDS alarms (percentage) | `number` | `80` | no |

## Outputs

| Name | Description |
|------|-------------|
| log_group_name | CloudWatch log group name |
| log_group_arn | CloudWatch log group ARN for cross-module references |
| dashboard_name | CloudWatch dashboard name |
| dashboard_url | CloudWatch dashboard URL |
| sns_topic_arn | SNS topic ARN for alerts |
| alarm_names | List of CloudWatch alarm names |
| connection_info | Connection details for other modules |