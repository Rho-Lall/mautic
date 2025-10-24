# DynamoDB Module

This Terraform module creates a DynamoDB table for storing lead capture data with encryption, backup, monitoring, and auto-scaling capabilities.

## Features

- **Encrypted Storage**: KMS encryption at rest with customer-managed keys
- **Global Secondary Indexes**: Email and source-based queries
- **Point-in-Time Recovery**: Continuous backups for data protection
- **Auto Scaling**: Automatic capacity adjustment for provisioned mode
- **CloudWatch Monitoring**: Performance and throttling alarms
- **TTL Support**: Automatic data expiration for compliance
- **Stream Support**: Change data capture for integrations

## Usage

### Basic Usage (Pay-per-Request)

```hcl
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name    = "lead-capture-leads"
  billing_mode  = "PAY_PER_REQUEST"
  
  # Security
  enable_encryption             = true
  enable_point_in_time_recovery = true
  
  # Monitoring
  enable_monitoring = true

  tags = {
    Environment = "production"
    Project     = "lead-capture"
  }
}
```

### Provisioned Capacity with Auto Scaling

```hcl
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name   = "lead-capture-leads"
  billing_mode = "PROVISIONED"
  
  # Initial capacity
  read_capacity  = 10
  write_capacity = 10
  
  # GSI capacity
  gsi_read_capacity  = 5
  gsi_write_capacity = 5
  
  # Auto scaling
  enable_autoscaling      = true
  read_min_capacity       = 5
  read_max_capacity       = 100
  write_min_capacity      = 5
  write_max_capacity      = 100
  read_target_utilization = 70
  write_target_utilization = 70
  
  # Security and backup
  enable_encryption             = true
  enable_point_in_time_recovery = true
  enable_backup                 = true
  
  tags = {
    Environment = "production"
    Project     = "lead-capture"
  }
}
```

### With TTL and Streams

```hcl
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name   = "lead-capture-leads"
  billing_mode = "PAY_PER_REQUEST"
  
  # TTL for GDPR compliance
  enable_ttl     = true
  ttl_attribute  = "expiresAt"
  
  # Streams for real-time processing
  enable_streams     = true
  stream_view_type   = "NEW_AND_OLD_IMAGES"
  
  # Security
  enable_encryption             = true
  enable_point_in_time_recovery = true
  kms_deletion_window          = 30
  
  tags = {
    Environment = "production"
    Project     = "lead-capture"
    Compliance  = "gdpr"
  }
}
```

## Variables

### Required Variables

None - all variables have sensible defaults.

### Optional Variables

| Name | Description | Type | Default | Validation |
|------|-------------|------|---------|------------|
| `table_name` | Name of the DynamoDB table | `string` | `"lead-capture-leads"` | - |
| `billing_mode` | DynamoDB billing mode | `string` | `"PAY_PER_REQUEST"` | Must be PROVISIONED or PAY_PER_REQUEST |
| `hash_key` | Hash key (partition key) for the table | `string` | `"leadId"` | - |
| `range_key` | Range key (sort key) for the table | `string` | `"timestamp"` | - |
| `read_capacity` | Read capacity units (PROVISIONED only) | `number` | `5` | - |
| `write_capacity` | Write capacity units (PROVISIONED only) | `number` | `5` | - |
| `gsi_read_capacity` | GSI read capacity units (PROVISIONED only) | `number` | `5` | - |
| `gsi_write_capacity` | GSI write capacity units (PROVISIONED only) | `number` | `5` | - |
| `enable_encryption` | Enable encryption at rest using KMS | `bool` | `true` | - |
| `kms_deletion_window` | KMS key deletion window in days | `number` | `7` | Between 7 and 30 days |
| `enable_point_in_time_recovery` | Enable point-in-time recovery | `bool` | `true` | - |
| `enable_ttl` | Enable TTL for automatic item expiration | `bool` | `false` | - |
| `ttl_attribute` | Attribute name for TTL | `string` | `"expiresAt"` | - |
| `enable_streams` | Enable DynamoDB streams | `bool` | `false` | - |
| `stream_view_type` | Stream view type | `string` | `"NEW_AND_OLD_IMAGES"` | Valid stream view type |
| `enable_backup` | Enable automatic backup creation | `bool` | `false` | - |
| `enable_autoscaling` | Enable auto scaling for provisioned capacity | `bool` | `false` | - |
| `read_min_capacity` | Minimum read capacity for auto scaling | `number` | `5` | - |
| `read_max_capacity` | Maximum read capacity for auto scaling | `number` | `100` | - |
| `write_min_capacity` | Minimum write capacity for auto scaling | `number` | `5` | - |
| `write_max_capacity` | Maximum write capacity for auto scaling | `number` | `100` | - |
| `read_target_utilization` | Target utilization % for read capacity | `number` | `70` | Between 20 and 90 percent |
| `write_target_utilization` | Target utilization % for write capacity | `number` | `70` | Between 20 and 90 percent |
| `enable_monitoring` | Enable CloudWatch monitoring and alarms | `bool` | `true` | - |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` | - |

### Variable Validation Rules

#### billing_mode
```hcl
validation {
  condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.billing_mode)
  error_message = "Billing mode must be either PROVISIONED or PAY_PER_REQUEST."
}
```

#### kms_deletion_window
```hcl
validation {
  condition     = var.kms_deletion_window >= 7 && var.kms_deletion_window <= 30
  error_message = "KMS deletion window must be between 7 and 30 days."
}
```

#### stream_view_type
```hcl
validation {
  condition = contains([
    "KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"
  ], var.stream_view_type)
  error_message = "Stream view type must be one of: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES."
}
```

#### read_target_utilization / write_target_utilization
```hcl
validation {
  condition     = var.read_target_utilization >= 20 && var.read_target_utilization <= 90
  error_message = "Read target utilization must be between 20 and 90 percent."
}
```

## Outputs

| Name | Description |
|------|-------------|
| `table_name` | Name of the DynamoDB table |
| `table_arn` | ARN of the DynamoDB table |
| `table_id` | ID of the DynamoDB table |
| `table_stream_arn` | ARN of the DynamoDB table stream (if enabled) |
| `table_stream_label` | Label of the DynamoDB table stream (if enabled) |
| `kms_key_id` | ID of the KMS key used for encryption (if enabled) |
| `kms_key_arn` | ARN of the KMS key used for encryption (if enabled) |
| `kms_key_alias` | Alias of the KMS key used for encryption (if enabled) |
| `email_gsi_name` | Name of the email Global Secondary Index |
| `source_gsi_name` | Name of the source Global Secondary Index |
| `hash_key` | Hash key of the DynamoDB table |
| `range_key` | Range key of the DynamoDB table |
| `billing_mode` | Billing mode of the DynamoDB table |
| `point_in_time_recovery_enabled` | Whether point-in-time recovery is enabled |
| `encryption_enabled` | Whether encryption at rest is enabled |
| `streams_enabled` | Whether DynamoDB streams are enabled |
| `ttl_enabled` | Whether TTL is enabled |
| `ttl_attribute` | TTL attribute name |

## Table Schema

### Primary Key Structure
- **Hash Key (Partition Key)**: `leadId` (String) - Unique identifier for each lead
- **Range Key (Sort Key)**: `timestamp` (String) - ISO timestamp of lead creation

### Global Secondary Indexes

#### Email Index
- **Hash Key**: `email` (String) - Lead's email address
- **Range Key**: `timestamp` (String) - Creation timestamp
- **Projection**: ALL attributes
- **Purpose**: Query leads by email address for deduplication

#### Source Index
- **Hash Key**: `source` (String) - Source website/domain
- **Range Key**: `timestamp` (String) - Creation timestamp
- **Projection**: ALL attributes
- **Purpose**: Query leads by source for analytics

### Sample Data Structure
```json
{
  "leadId": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2025-10-23T10:30:00.000Z",
  "email": "john.doe@example.com",
  "source": "mywebsite.com",
  "name": "John Doe",
  "company": "Example Corp",
  "phone": "+1-555-123-4567",
  "customFields": {
    "interests": "product-demo",
    "budget": "10k-50k"
  },
  "metadata": {
    "userAgent": "Mozilla/5.0...",
    "ipAddress": "192.168.1.1",
    "referrer": "https://google.com"
  },
  "expiresAt": 1735689000
}
```

## Security Features

### Encryption at Rest
- **KMS Encryption**: Customer-managed KMS key
- **Key Rotation**: Automatic annual rotation
- **Key Alias**: Human-readable key identifier
- **Deletion Protection**: Configurable deletion window

### Access Control
- **IAM Integration**: Fine-grained permissions
- **Least Privilege**: Minimal required permissions
- **Resource-based Policies**: Table-level access control

### Data Protection
- **Point-in-Time Recovery**: Continuous backups
- **Backup Retention**: Configurable retention periods
- **Stream Encryption**: Encrypted change streams

## Performance and Scaling

### Billing Modes

#### Pay-per-Request (On-Demand)
- **Best for**: Unpredictable traffic patterns
- **Scaling**: Automatic, instant scaling
- **Cost**: Pay only for actual usage
- **Limits**: No capacity planning required

#### Provisioned Capacity
- **Best for**: Predictable traffic patterns
- **Scaling**: Manual or auto-scaling
- **Cost**: Lower cost for consistent usage
- **Limits**: Requires capacity planning

### Auto Scaling (Provisioned Mode)
- **Target Utilization**: 70% default (configurable)
- **Scale Up**: Immediate when utilization exceeds target
- **Scale Down**: Gradual to prevent thrashing
- **Limits**: Configurable min/max capacity

### Global Secondary Indexes
- **Email Index**: Fast email-based lookups
- **Source Index**: Analytics and reporting queries
- **Projection**: ALL attributes for complete data access
- **Consistency**: Eventually consistent reads

## Monitoring and Alarms

### CloudWatch Metrics
- **Read/Write Capacity**: Utilization monitoring
- **Throttled Requests**: Performance issues detection
- **Error Rates**: Application health monitoring
- **Latency**: Response time tracking

### CloudWatch Alarms
- **Read Throttling**: Alerts when reads are throttled
- **Write Throttling**: Alerts when writes are throttled
- **Configurable Thresholds**: Customizable alert levels

## Data Lifecycle Management

### TTL (Time To Live)
- **Purpose**: Automatic data expiration for compliance
- **Attribute**: Configurable TTL attribute name
- **Format**: Unix timestamp (seconds since epoch)
- **Deletion**: Automatic, eventual consistency

### Backup Strategy
- **Point-in-Time Recovery**: Continuous backups (35 days)
- **On-Demand Backups**: Manual backup creation
- **Cross-Region**: Optional cross-region replication

## Integration Patterns

### DynamoDB Streams
- **Change Capture**: Real-time data change notifications
- **Lambda Triggers**: Process changes automatically
- **View Types**: Keys only, new/old images, or both
- **Retention**: 24-hour stream retention

### Common Integration Scenarios
1. **Real-time Analytics**: Stream to Kinesis Analytics
2. **Search Integration**: Stream to Elasticsearch
3. **Audit Logging**: Stream to CloudWatch Logs
4. **Data Replication**: Stream to another DynamoDB table

## Cost Optimization

### Pay-per-Request vs Provisioned
- **Pay-per-Request**: Better for sporadic traffic
- **Provisioned**: Better for consistent, predictable traffic
- **Break-even**: ~40% utilization of provisioned capacity

### Storage Optimization
- **Item Size**: Minimize attribute sizes
- **Sparse Indexes**: Use GSIs efficiently
- **TTL**: Remove old data automatically
- **Compression**: Compress large text fields

## Troubleshooting

### Common Issues

1. **Throttling**: Increase capacity or enable auto-scaling
2. **Hot Partitions**: Distribute partition keys evenly
3. **Large Items**: Keep items under 400KB limit
4. **GSI Throttling**: Monitor GSI capacity separately

### Performance Tuning

1. **Partition Key Design**: Ensure even distribution
2. **Query Patterns**: Use GSIs for different access patterns
3. **Batch Operations**: Use batch APIs for bulk operations
4. **Connection Pooling**: Reuse DynamoDB connections

### Monitoring Best Practices

1. **Set Up Alarms**: Monitor throttling and errors
2. **Track Metrics**: Monitor capacity utilization
3. **Log Queries**: Enable CloudTrail for API calls
4. **Performance Testing**: Load test before production

## Dependencies

This module requires:
- **AWS Provider**: Version ~> 5.0
- **Terraform**: Version >= 1.0

## Integration with Other Modules

This module integrates with:
- **Lambda Module**: Provides database access for functions
- **API Gateway Module**: Stores data from API requests
- **SES Module**: May trigger based on DynamoDB streams