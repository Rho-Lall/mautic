# Load Balancer Module - Main Configuration
# This module creates an Application Load Balancer for Mautic deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2              = var.enable_http2
  idle_timeout              = var.idle_timeout
  drop_invalid_header_fields = var.drop_invalid_header_fields

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Module      = "load-balancer"
  })
}

# Target Group
resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = var.target_port
  protocol = var.target_protocol
  vpc_id   = var.vpc_id

  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    protocol            = var.health_check_protocol
    port                = var.health_check_port
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-tg"
    Environment = var.environment
    Module      = "load-balancer"
  })
}

# HTTP Listener (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  count             = var.enable_https_redirect && var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      host        = "#{host}"
      path        = "/#{path}"
      query       = "#{query}"
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-http-redirect"
    Environment = var.environment
    Module      = "load-balancer"
  })
}

# HTTPS Listener with security headers
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-https-listener"
    Environment = var.environment
    Module      = "load-balancer"
  })
}

# Security headers listener rule for HTTPS
resource "aws_lb_listener_rule" "security_headers_https" {
  count        = var.certificate_arn != null && var.enable_security_headers ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-security-headers-https"
    Environment = var.environment
    Module      = "load-balancer"
  })
}

# Security headers listener rule for HTTP (when no HTTPS redirect)
resource "aws_lb_listener_rule" "security_headers_http" {
  count        = var.certificate_arn == null && var.enable_security_headers ? 1 : 0
  listener_arn = aws_lb_listener.http_only[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-security-headers-http"
    Environment = var.environment
    Module      = "load-balancer"
  })
}

# HTTP Listener (when HTTPS is not configured)
resource "aws_lb_listener" "http_only" {
  count             = var.certificate_arn == null ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-http-listener"
    Environment = var.environment
    Module      = "load-balancer"
  })
}