# Networking Module

This module creates a complete VPC infrastructure with public and private subnets, NAT gateways, and security groups for Mautic deployment.

## Features

- VPC with configurable CIDR block
- Public and private subnets across multiple AZs
- Internet Gateway for public subnet access
- NAT Gateways for private subnet internet access
- Security groups with least-privilege access patterns
- Route tables and associations

## Usage

```hcl
module "networking" {
  source = "./modules/networking"

  project_name = "my-project"
  environment  = "dev"
  
  vpc_cidr              = "10.0.0.0/16"
  public_subnet_count   = 2
  private_subnet_count  = 2
  
  enable_nat_gateway = true
  nat_gateway_count  = 1
  
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
| vpc_cidr | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| public_subnet_count | Number of public subnets to create | `number` | `2` | no |
| private_subnet_count | Number of private subnets to create | `number` | `2` | no |
| enable_nat_gateway | Enable NAT Gateway for private subnets | `bool` | `true` | no |
| nat_gateway_count | Number of NAT Gateways to create | `number` | `1` | no |
| alb_ingress_cidr_blocks | CIDR blocks allowed to access the ALB | `list(string)` | `["0.0.0.0/0"]` | no |
| container_port | Port on which the container receives traffic | `number` | `80` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC identifier |
| vpc_arn | VPC ARN for cross-module references |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| alb_security_group_id | Security group ID for Application Load Balancer |
| ecs_tasks_security_group_id | Security group ID for ECS tasks |
| rds_security_group_id | Security group ID for RDS database |
| connection_info | Connection details for other modules |