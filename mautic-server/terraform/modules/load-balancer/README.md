# Load Balancer Module

This module creates an Application Load Balancer (ALB) with target groups and listeners for Mautic deployment.

## Features

- Application Load Balancer with configurable listeners
- HTTP to HTTPS redirect support with path and query preservation
- SSL/TLS termination with custom certificates and configurable SSL policies
- Health checks with configurable parameters
- Target group for ECS service integration
- Security headers and best practices implementation
- Invalid header field dropping for enhanced security
- Optional access logging to S3
- Configurable security headers for improved web security

## Usage

```hcl
module "load_balancer" {
  source = "./modules/load-balancer"

  project_name = "my-project"
  environment  = "dev"
  
  vpc_id             = "vpc-12345"
  subnet_ids         = ["subnet-12345", "subnet-67890"]
  security_group_ids = ["sg-abcdef"]
  
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  
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
| vpc_id | VPC ID where the load balancer will be created | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the load balancer | `list(string)` | n/a | yes |
| security_group_ids | List of security group IDs for the load balancer | `list(string)` | n/a | yes |
| tags | Common tags for all resources | `map(string)` | `{}` | no |
| internal | Whether the load balancer is internal | `bool` | `false` | no |
| enable_deletion_protection | Enable deletion protection for the load balancer | `bool` | `false` | no |
| target_port | Port on which targets receive traffic | `number` | `80` | no |
| target_protocol | Protocol to use for routing traffic to targets | `string` | `"HTTP"` | no |
| health_check_path | Health check path | `string` | `"/"` | no |
| certificate_arn | ARN of the SSL certificate for HTTPS listener | `string` | `null` | no |
| enable_https_redirect | Enable HTTP to HTTPS redirect | `bool` | `true` | no |
| enable_security_headers | Enable security headers in responses | `bool` | `true` | no |
| security_headers | Security headers to add to responses | `map(string)` | See variables.tf | no |
| drop_invalid_header_fields | Drop invalid header fields to improve security | `bool` | `true` | no |
| enable_access_logs | Enable access logs for the load balancer | `bool` | `false` | no |
| access_logs_bucket | S3 bucket name for access logs | `string` | `null` | no |
| access_logs_prefix | S3 prefix for access logs | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| load_balancer_id | Load balancer identifier |
| load_balancer_arn | Load balancer ARN for cross-module references |
| load_balancer_dns_name | DNS name of the load balancer |
| target_group_arn | Target group ARN for cross-module references |
| connection_info | Connection details for other modules |