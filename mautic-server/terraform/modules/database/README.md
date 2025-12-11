# Database Module

This module creates an Amazon RDS MySQL instance for Mautic deployment with encryption, backup, and monitoring capabilities.

## Features

- RDS MySQL instance with configurable engine version
- Encryption at rest enabled by default
- Automated backups with configurable retention
- Enhanced monitoring support
- Custom parameter group support
- Multi-AZ deployment capability

## Usage

```hcl
module "database" {
  source = "./modules/database"

  project_name = "my-project"
  environment  = "dev"
  
  subnet_ids         = ["subnet-12345", "subnet-67890"]
  security_group_ids = ["sg-abcdef"]
  
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  
  master_password = var.db_password
  
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
| subnet_ids | List of subnet IDs for the DB subnet group | `list(string)` | n/a | yes |
| security_group_ids | List of security group IDs for the database | `list(string)` | n/a | yes |
| master_password | Master password for the database | `string` | n/a | yes |
| tags | Common tags for all resources | `map(string)` | `{}` | no |
| publicly_accessible | Whether the database should be publicly accessible | `bool` | `false` | no |
| engine_version | MySQL engine version | `string` | `"8.0"` | no |
| instance_class | RDS instance class | `string` | `"db.t3.micro"` | no |
| allocated_storage | Initial allocated storage in GB | `number` | `20` | no |
| storage_encrypted | Enable storage encryption | `bool` | `true` | no |
| database_name | Name of the database to create | `string` | `"mautic"` | no |
| master_username | Master username for the database | `string` | `"mautic_admin"` | no |
| backup_retention_period | Backup retention period in days | `number` | `7` | no |
| deletion_protection | Enable deletion protection | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_id | RDS instance identifier |
| db_instance_arn | RDS instance ARN for cross-module references |
| db_instance_endpoint | RDS instance endpoint |
| db_instance_port | RDS instance port |
| connection_info | Connection details for other modules |
| database_credentials | Database connection credentials |