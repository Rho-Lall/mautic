# Networking Module - Main Configuration
# This module creates VPC, subnets, and security groups for Mautic deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  count = var.create_resources ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Module      = "networking"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count = var.create_resources ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Module      = "networking"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = var.create_resources ? var.public_subnet_count : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.subnet_newbits, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Module      = "networking"
    Type        = "public"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = var.create_resources ? var.private_subnet_count : 0

  vpc_id            = aws_vpc.main[0].id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_newbits, var.public_subnet_count + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Module      = "networking"
    Type        = "private"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.create_resources && var.enable_nat_gateway ? var.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
    Environment = var.environment
    Module      = "networking"
  })

  depends_on = [aws_internet_gateway.main]

  lifecycle {
    prevent_destroy = false
  }
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.create_resources && var.enable_nat_gateway ? var.nat_gateway_count : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-nat-gw-${count.index + 1}"
    Environment = var.environment
    Module      = "networking"
  })

  depends_on = [aws_internet_gateway.main]

  lifecycle {
    prevent_destroy = true
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  count = var.create_resources ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
    Module      = "networking"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Private Route Tables
resource "aws_route_table" "private" {
  count = var.create_resources ? (var.enable_nat_gateway ? var.nat_gateway_count : 1) : 0

  vpc_id = aws_vpc.main[0].id

  dynamic "route" {
    for_each = var.enable_nat_gateway && length(aws_nat_gateway.main) > 0 ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index % length(aws_nat_gateway.main)].id
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
    Environment = var.environment
    Module      = "networking"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count = var.create_resources ? var.public_subnet_count : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count = var.create_resources ? var.private_subnet_count : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index % length(aws_route_table.private)].id
}

# Security Group for Load Balancer
resource "aws_security_group" "alb" {
  count = var.create_resources ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-alb-"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidr_blocks
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidr_blocks
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
    Module      = "networking"
  })

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
  }
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  count = var.create_resources ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-ecs-tasks-"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    description     = "HTTP from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb[0].id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-ecs-tasks-sg"
    Environment = var.environment
    Module      = "networking"
  })

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  count = var.create_resources ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-rds-"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    description     = "MySQL from ECS tasks"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks[0].id]
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Environment = var.environment
    Module      = "networking"
  })

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
  }
}