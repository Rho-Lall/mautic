# KMS Key for DynamoDB encryption
resource "aws_kms_key" "dynamodb_key" {
  count = var.enable_encryption ? 1 : 0

  description             = "KMS key for DynamoDB table encryption"
  deletion_window_in_days = var.kms_deletion_window

  tags = merge(var.tags, {
    Name = "${var.table_name}-encryption-key"
  })
}

# KMS Key Alias
resource "aws_kms_alias" "dynamodb_key_alias" {
  count = var.enable_encryption ? 1 : 0

  name          = "alias/${var.table_name}-encryption-key"
  target_key_id = aws_kms_key.dynamodb_key[0].key_id
}

# DynamoDB Table
resource "aws_dynamodb_table" "leads_table" {
  name           = var.table_name
  billing_mode   = var.billing_mode
  hash_key       = var.hash_key
  range_key      = var.range_key

  # Provisioned throughput (only used if billing_mode is PROVISIONED)
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # Attributes
  attribute {
    name = var.hash_key
    type = "S"
  }

  attribute {
    name = var.range_key
    type = "S"
  }

  # Email GSI attribute
  attribute {
    name = "email"
    type = "S"
  }

  # Source GSI attribute
  attribute {
    name = "source"
    type = "S"
  }

  # Global Secondary Index for email lookups
  global_secondary_index {
    name            = "email-index"
    hash_key        = "email"
    range_key       = var.range_key
    projection_type = "ALL"

    read_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  # Global Secondary Index for source-based queries
  global_secondary_index {
    name            = "source-index"
    hash_key        = "source"
    range_key       = var.range_key
    projection_type = "ALL"

    read_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  # TTL configuration
  ttl {
    attribute_name = var.ttl_attribute
    enabled        = var.enable_ttl
  }

  # Encryption at rest
  server_side_encryption {
    enabled     = var.enable_encryption
    kms_key_id  = var.enable_encryption ? aws_kms_key.dynamodb_key[0].arn : null
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  # Stream configuration
  stream_enabled   = var.enable_streams
  stream_view_type = var.enable_streams ? var.stream_view_type : null

  tags = merge(var.tags, {
    Name = var.table_name
  })

  lifecycle {
    prevent_destroy = true
  }
}

# DynamoDB Table Backup
resource "aws_dynamodb_backup" "leads_table_backup" {
  count = var.enable_backup ? 1 : 0

  name     = "${var.table_name}-backup-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  table_name = aws_dynamodb_table.leads_table.name

  tags = var.tags
}

# Auto Scaling for Read Capacity (if using provisioned billing)
resource "aws_appautoscaling_target" "read_target" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.read_max_capacity
  min_capacity       = var.read_min_capacity
  resource_id        = "table/${aws_dynamodb_table.leads_table.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "read_policy" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  name               = "${var.table_name}-read-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.read_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.read_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = var.read_target_utilization
  }
}

# Auto Scaling for Write Capacity (if using provisioned billing)
resource "aws_appautoscaling_target" "write_target" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.write_max_capacity
  min_capacity       = var.write_min_capacity
  resource_id        = "table/${aws_dynamodb_table.leads_table.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "write_policy" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  name               = "${var.table_name}-write-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.write_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.write_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.write_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = var.write_target_utilization
  }
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "read_throttled_requests" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.table_name}-read-throttled-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors read throttled requests"

  dimensions = {
    TableName = aws_dynamodb_table.leads_table.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "write_throttled_requests" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.table_name}-write-throttled-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors write throttled requests"

  dimensions = {
    TableName = aws_dynamodb_table.leads_table.name
  }

  tags = var.tags
}