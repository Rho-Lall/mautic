# Basic Mautic Deployment Example
# This example demonstrates a minimal Mautic deployment using the public modules

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Common tags for all resources
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Example     = "basic-setup"
  }
}

# Networking Module
module "networking" {
  source = "../../terraform/modules/networking"

  project_name = var.project_name
  environment  = var.environment
  
  vpc_cidr              = var.vpc_cidr
  public_subnet_count   = 2
  private_subnet_count  = 2
  enable_nat_gateway    = true
  nat_gateway_count     = 1

  tags = local.common_tags
}

# Database Module
module "database" {
  source = "../../terraform/modules/database"

  project_name = var.project_name
  environment  = var.environment
  
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [module.networking.rds_security_group_id]
  
  instance_class      = var.db_instance_class
  allocated_storage   = var.db_allocated_storage
  master_password     = var.db_password
  
  backup_retention_period = 7
  deletion_protection     = false  # Set to true for production

  tags = local.common_tags
}

# ECS Cluster Module
module "ecs_cluster" {
  source = "../../terraform/modules/ecs-cluster"

  project_name = var.project_name
  environment  = var.environment
  
  enable_container_insights = true
  enable_fargate_spot      = false  # Set to true for cost optimization

  tags = local.common_tags
}

# Load Balancer Module
module "load_balancer" {
  source = "../../terraform/modules/load-balancer"

  project_name = var.project_name
  environment  = var.environment
  
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.public_subnet_ids
  security_group_ids = [module.networking.alb_security_group_id]
  
  # SSL certificate (optional)
  certificate_arn        = var.ssl_certificate_arn
  enable_https_redirect  = var.ssl_certificate_arn != null

  tags = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "../../terraform/modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  
  # Resource references for monitoring
  ecs_cluster_name = module.ecs_cluster.cluster_name
  ecs_service_name = "${var.project_name}-${var.environment}-mautic-service"
  alb_arn_suffix   = module.load_balancer.load_balancer_arn
  rds_instance_id  = module.database.db_instance_id
  
  # Alert configuration
  enable_alerts = var.enable_monitoring_alerts
  
  log_retention_days = 7

  tags = local.common_tags
}

# Secrets for Mautic configuration
resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.project_name}-${var.environment}-db-password"
  description = "Database password for Mautic"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

resource "aws_secretsmanager_secret" "mautic_secret_key" {
  name        = "${var.project_name}-${var.environment}-mautic-secret"
  description = "Mautic secret key"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "mautic_secret_key" {
  secret_id     = aws_secretsmanager_secret.mautic_secret_key.id
  secret_string = var.mautic_secret_key
}

# Mautic Service Module
module "mautic_service" {
  source = "../../terraform/modules/mautic-service"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  
  # ECS Configuration
  ecs_cluster_id        = module.ecs_cluster.cluster_id
  private_subnet_ids    = module.networking.private_subnet_ids
  ecs_security_group_id = module.networking.ecs_tasks_security_group_id
  target_group_arn      = module.load_balancer.target_group_arn
  log_group_name        = module.monitoring.log_group_name
  
  # Task Configuration
  task_cpu      = var.task_cpu
  task_memory   = var.task_memory
  desired_count = var.desired_count
  
  # Mautic Configuration
  database_host                = module.database.db_instance_endpoint
  database_name                = "mautic"
  database_user                = "mautic_admin"
  database_password_secret_arn = aws_secretsmanager_secret.db_password.arn
  secret_key_secret_arn       = aws_secretsmanager_secret.mautic_secret_key.arn
  trusted_hosts               = var.trusted_hosts

  tags = local.common_tags
}