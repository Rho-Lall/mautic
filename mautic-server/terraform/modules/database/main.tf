# Database Module - Main Configuration
# This module creates an RDS MySQL instance for Mautic deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Module      = "database"
  })
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  family = var.parameter_group_family
  name   = "${var.project_name}-${var.environment}-db-params"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-db-params"
    Environment = var.environment
    Module      = "database"
  })
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  # Engine Configuration
  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage Configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id           = var.kms_key_id

  # Database Configuration
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = var.publicly_accessible
  port                   = var.database_port

  # Backup Configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  copy_tags_to_snapshot  = true

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.main.name

  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_role_arn

  # Deletion Protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-db"
    Environment = var.environment
    Module      = "database"
  })
}