# Mautic Server - Public Modules

This repository contains reusable, open-source Terraform modules and Docker configuration for deploying Mautic marketing automation platform on AWS infrastructure. The modules are designed to be generic, secure, and customizable without exposing any sensitive information.

## Overview

The Mautic Server public modules provide:

- **Terraform Modules**: Reusable infrastructure templates for AWS
- **Docker Configuration**: Vanilla Mautic container setup
- **Security Best Practices**: Least-privilege access and encryption by default
- **Modular Design**: Mix and match components based on your needs

## Architecture

```
mautic-server/
├── terraform/modules/
│   ├── ecs-cluster/          # ECS Fargate cluster
│   ├── mautic-service/       # Mautic-specific ECS service
│   ├── database/             # RDS MySQL with encryption
│   ├── load-balancer/        # Application Load Balancer
│   ├── networking/           # VPC, subnets, security groups
│   └── monitoring/           # CloudWatch dashboards and alarms
└── docker/
    ├── Dockerfile           # Vanilla Mautic container
    └── config/              # Basic configuration templates
```

## Quick Start

### 1. Basic Infrastructure Setup

```hcl
# main.tf
module "networking" {
  source = "./terraform/modules/networking"
  
  project_name = "my-mautic"
  environment  = "dev"
  vpc_cidr     = "10.0.0.0/16"
}

module "database" {
  source = "./terraform/modules/database"
  
  project_name       = "my-mautic"
  environment        = "dev"
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [module.networking.rds_security_group_id]
  master_password    = var.db_password
}

module "ecs_cluster" {
  source = "./terraform/modules/ecs-cluster"
  
  project_name = "my-mautic"
  environment  = "dev"
}

module "load_balancer" {
  source = "./terraform/modules/load-balancer"
  
  project_name       = "my-mautic"
  environment        = "dev"
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.public_subnet_ids
  security_group_ids = [module.networking.alb_security_group_id]
}
```

### 2. Mautic Service Deployment

```hcl
module "mautic_service" {
  source = "./terraform/modules/mautic-service"
  
  project_name          = "my-mautic"
  environment           = "dev"
  ecs_cluster_id        = module.ecs_cluster.cluster_id
  private_subnet_ids    = module.networking.private_subnet_ids
  ecs_security_group_id = module.networking.ecs_tasks_security_group_id
  target_group_arn      = module.load_balancer.target_group_arn
  
  database_host                = module.database.db_instance_endpoint
  database_password_secret_arn = aws_secretsmanager_secret.db_password.arn
  secret_key_secret_arn       = aws_secretsmanager_secret.mautic_key.arn
}
```

## Module Features

### Networking Module
- VPC with public and private subnets
- NAT Gateways for private subnet internet access
- Security groups with least-privilege access
- Configurable CIDR blocks and subnet counts

### Database Module
- RDS MySQL with encryption at rest
- Automated backups and maintenance windows
- Multi-AZ deployment support
- Custom parameter groups

### ECS Cluster Module
- Fargate cluster with capacity providers
- Container Insights support
- Fargate Spot integration

### Load Balancer Module
- Application Load Balancer with SSL termination
- Health checks and target groups
- HTTP to HTTPS redirect

### Mautic Service Module
- ECS service with Fargate launch type
- Secrets Manager integration
- IAM roles with minimal permissions
- Health checks and logging

### Monitoring Module
- CloudWatch dashboards
- Configurable alarms
- Log groups for container logs
- SNS notifications

## Docker Configuration

The included Dockerfile extends the official Mautic image without modifications:

```dockerfile
FROM mautic/mautic:latest

# Environment variables for configuration
ENV MAUTIC_DB_HOST=""
ENV MAUTIC_DB_PORT="3306"
ENV MAUTIC_DB_NAME=""
ENV MAUTIC_DB_USER=""
ENV MAUTIC_DB_PASSWORD=""
ENV MAUTIC_TRUSTED_HOSTS=""
ENV MAUTIC_SECRET_KEY=""

# Health check configuration
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/health || exit 1
```

## Security Features

- **No Hardcoded Secrets**: All sensitive data uses variables or Secrets Manager
- **Encryption by Default**: RDS encryption and SSL/TLS termination
- **Least-Privilege Access**: IAM roles with minimal required permissions
- **Private Networking**: Application and database in private subnets
- **Security Groups**: Restrictive ingress/egress rules

## Requirements

- Terraform >= 1.0
- AWS Provider ~> 5.0
- Docker (for container builds)

## Variables

Each module accepts standard variables:

- `project_name`: Project identifier for resource naming
- `environment`: Environment name (dev, staging, prod)
- `tags`: Common tags for all resources

See individual module README files for complete variable documentation.

## Outputs

Modules provide consistent outputs for interconnection:

- Resource identifiers and ARNs
- Connection information for other modules
- Network and security configurations

## Examples

See the `examples/` directory for complete deployment examples:

- Basic setup with minimal configuration
- Production setup with high availability
- Custom configuration examples

## Contributing

This is a public module repository. Contributions should:

- Follow security best practices
- Include no sensitive information
- Maintain backward compatibility
- Include appropriate documentation

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:

1. Check the module README files
2. Review the examples directory
3. Open an issue with detailed information
4. Follow the security policy for sensitive issues