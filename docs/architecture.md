# Architecture

This document describes the overall architecture of the Mautic Marketing Automation Suite.

## System Overview

The suite demonstrates two distinct architectural patterns:

1. **Serverless Lead Capture** - Event-driven, fully managed services
2. **Mautic Server** - Container-based application with managed database

These components are designed to work independently, showcasing different AWS deployment strategies.

```
┌─────────────────┐
│ Static Website  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ Serverless Lead Capture │
│  - API Gateway          │
│  - Lambda Functions     │
│  - DynamoDB             │
└─────────────────────────┘

┌─────────────────────────┐
│   Mautic Server         │
│  - ALB                  │
│  - ECS Fargate          │
│  - RDS MySQL            │
│  - SES (SMTP)           │
└─────────────────────────┘
```

## Serverless Lead Capture

### Components

**API Gateway**
- HTTP REST API
- CORS configuration
- API key authentication
- Request validation

**Lambda Functions**
- `submit-lead`: Process form submissions
- `get-leads`: Retrieve lead data
- Node.js 18 runtime
- Environment-based configuration

**DynamoDB**
- Single table design
- On-demand billing
- Point-in-time recovery
- Encryption at rest

**CloudWatch**
- Lambda function logs
- API Gateway access logs
- Custom metrics
- Alarms and notifications

### Data Flow

1. User submits form on website
2. Browser sends POST to API Gateway
3. API Gateway validates and forwards to Lambda
4. Lambda validates data and writes to DynamoDB
5. Lambda returns success/error response
6. Optional: SES sends notification email

### Security

- CORS restrictions
- API key authentication
- Input validation
- Encryption at rest and in transit
- IAM least-privilege policies

## Mautic Server

### Components

**ECS (Elastic Container Service)**
- Fargate launch type
- Auto-scaling based on load
- Health checks and monitoring
- Rolling deployments

**RDS (Relational Database Service)**
- MySQL 8.0
- Multi-AZ for high availability
- Automated backups
- Encryption at rest

**Application Load Balancer**
- SSL termination
- Health checks
- Target group routing
- Optional WAF integration

**SES (Simple Email Service)**
- SMTP transport for Mautic
- Custom domain configuration (DKIM, SPF, DMARC)
- Bounce and complaint handling
- CloudWatch monitoring and alarms

**Networking**
- VPC with public and private subnets
- Security groups for ALB, ECS, and RDS
- NAT Gateway for outbound traffic
- Route 53 for custom domain (optional)

**Secrets Management**
- AWS Secrets Manager for sensitive data
- Database passwords
- Mautic secret key
- Admin credentials

### Data Flow

1. User accesses Mautic UI via ALB
2. ALB routes to ECS Fargate tasks
3. ECS serves Mautic application
4. Application reads/writes to RDS MySQL
5. Emails sent via SES SMTP
6. CloudWatch monitors all components

## Integration Patterns

### Future Integration: Lead Capture → Mautic

Potential integration approaches:

- **DynamoDB Streams**: Trigger Lambda on new leads
- **API Integration**: Lambda calls Mautic REST API
- **Webhook**: API Gateway webhook to Mautic
- **Batch Import**: Scheduled Lambda for bulk import

### Extensibility

The modular architecture supports additional integrations:

- **n8n Workflows**: Event-driven automation (ECS Fargate)
- **EventBridge**: Cross-service event routing
- **SQS/SNS**: Asynchronous messaging
- **Step Functions**: Complex workflow orchestration

## Infrastructure as Code

All infrastructure is defined using Terraform:

- **Modules**: Reusable components
- **Environments**: Dev, staging, production
- **State Management**: S3 + DynamoDB
- **Version Control**: Git-based workflow

## Deployment Strategy

### Development
- Single environment
- Relaxed CORS
- Debug logging enabled
- Cost-optimized resources

### Production
- Multi-AZ deployment
- Strict CORS policies
- Production logging
- High-availability configuration
- Automated backups
- Monitoring and alerting

## Monitoring and Observability

### CloudWatch
- Centralized logging
- Custom metrics
- Dashboards
- Alarms

### X-Ray (Optional)
- Distributed tracing
- Performance analysis
- Error tracking

### Cost Monitoring
- AWS Cost Explorer
- Budget alerts
- Resource tagging

## Disaster Recovery

### Backup Strategy
- RDS automated backups (7-day retention)
- DynamoDB point-in-time recovery
- S3 versioning for assets
- Infrastructure as Code in Git

### Recovery Procedures
- Database restore from backup
- DynamoDB table restore
- Infrastructure recreation via Terraform
- DNS failover (if multi-region)

## Scalability

### Serverless Components
- Automatic scaling
- Pay-per-use pricing
- No capacity planning needed

### Container Components
- ECS auto-scaling (CPU and memory-based)
- RDS vertical scaling (instance class)
- RDS read replicas (for read-heavy workloads)
- ALB for horizontal distribution

## Security Best Practices

- Encryption at rest and in transit
- IAM least-privilege policies
- VPC isolation
- Security group restrictions
- Regular security audits
- Automated vulnerability scanning
- Secrets management (AWS Secrets Manager)
