# Mautic Server

Self-hosted Mautic marketing automation platform deployed on AWS using ECS, demonstrating production-ready container orchestration and infrastructure design.

## Overview

This implementation showcases a fully containerized Mautic deployment with supporting AWS services, designed for scalability, reliability, and operational excellence.

## Architecture

```
Internet
    ↓
Application Load Balancer (ALB)
    ↓
ECS Fargate (Mautic Container)
    ↓
├─→ RDS MySQL (Database)
├─→ ElastiCache Redis (Cache/Sessions)
└─→ AWS SES (Email Sending)
```

## Infrastructure Components

### Container Orchestration
- **ECS Fargate**: Serverless container management
- **Docker**: Custom Mautic container with optimized configuration
- **Auto-scaling**: CPU and memory-based scaling policies
- **Health checks**: Application-level monitoring

### Database Layer
- **RDS MySQL 8.0**: Multi-AZ deployment for high availability
- **Automated backups**: Point-in-time recovery enabled
- **Encryption**: At-rest encryption with AWS KMS
- **Performance Insights**: Query performance monitoring

### Caching & Sessions
- **ElastiCache Redis**: Session management and application caching
- **Cluster mode**: High availability configuration
- **Automatic failover**: Multi-AZ deployment
- **Encryption**: In-transit and at-rest encryption

### Load Balancing
- **Application Load Balancer**: Layer 7 load balancing
- **SSL/TLS termination**: Certificate management via ACM
- **Health checks**: Target group health monitoring
- **Access logs**: Request logging to S3

### Email Infrastructure
- **AWS SES**: Production email sending
- **Custom domain**: DKIM, SPF, and DMARC configuration
- **SMTP integration**: Mautic email transport configuration
- **Monitoring**: Bounce and complaint tracking

## Terraform Modules

The infrastructure is organized into reusable Terraform modules:

```
terraform/
├── modules/
│   ├── networking/        # VPC, subnets, security groups
│   ├── database/          # RDS MySQL configuration
│   ├── ecs-cluster/       # ECS cluster and capacity providers
│   ├── load-balancer/     # ALB with SSL and WAF
│   ├── mautic-service/    # ECS service and task definition
│   ├── monitoring/        # CloudWatch dashboards and alarms
│   └── ses/               # Email infrastructure
└── environments/
    ├── dev/               # Development environment
    ├── test/              # Testing environment
    └── prod/              # Production environment
```

## Key Features

### Security
- **VPC isolation**: Private subnets for application and database
- **Security groups**: Least-privilege network access
- **Secrets management**: AWS Secrets Manager for sensitive data
- **IAM roles**: Task-level permissions with least privilege
- **Encryption**: All data encrypted at rest and in transit

### Monitoring & Observability
- **CloudWatch dashboards**: Real-time metrics visualization
- **Custom alarms**: CPU, memory, database, and application metrics
- **Log aggregation**: Centralized logging with CloudWatch Logs
- **SES monitoring**: Email delivery, bounce, and complaint tracking

### High Availability
- **Multi-AZ deployment**: Database and cache redundancy
- **Auto-scaling**: Automatic capacity adjustment
- **Health checks**: Automated failure detection and recovery
- **Backup strategy**: Automated database backups with retention

### Cost Optimization
- **Fargate Spot**: Cost-effective compute for non-critical workloads
- **RDS instance sizing**: Right-sized for workload requirements
- **ElastiCache optimization**: Appropriate node types and replication
- **Resource tagging**: Cost allocation and tracking

## Configuration Management

### Environment Variables
Mautic configuration managed through ECS task definition:
- Database connection parameters
- Redis cache configuration
- SES SMTP credentials
- Application settings

### Secrets Management
Sensitive data stored in AWS Secrets Manager:
- Database passwords
- Mautic secret key
- Admin credentials
- Email configuration

## Testing

### Infrastructure Testing
Property-based testing using Hypothesis and pytest:
- DNS configuration validation
- IAM policy verification
- SES domain setup testing
- Resource tagging compliance

### Test Coverage
```
terraform/tests/
├── test_dns_verification_property.py
├── test_dkim_dns_property.py
├── test_spf_record_property.py
├── test_dmarc_record_property.py
├── test_iam_policy_*.py
└── test_ses_*.py
```

## Deployment

### Multi-Environment Strategy
- **Development**: Single-AZ, minimal resources, debug logging
- **Test**: Production-like, automated testing, staging data
- **Production**: Multi-AZ, high availability, production data

### Deployment Process
1. Terraform plan and validation
2. Infrastructure deployment
3. Database initialization
4. Mautic container deployment
5. DNS and SSL configuration
6. Monitoring and alerting setup

## Performance Characteristics

### Scalability
- **Horizontal scaling**: ECS task count adjustment
- **Vertical scaling**: Task CPU and memory configuration
- **Database scaling**: RDS instance class modification
- **Cache scaling**: ElastiCache node type adjustment

### Reliability
- **Multi-AZ deployment**: 99.95% availability SLA
- **Automated failover**: Database and cache redundancy
- **Health monitoring**: Continuous health checks
- **Backup and recovery**: Automated backup with point-in-time recovery

## Operational Considerations

### Maintenance
- **Zero-downtime deployments**: Rolling updates with health checks
- **Database migrations**: Automated schema management
- **Backup verification**: Regular restore testing
- **Security patching**: Automated container updates

### Monitoring
- **Application metrics**: Request rates, response times, error rates
- **Infrastructure metrics**: CPU, memory, disk, network
- **Database metrics**: Connections, queries, replication lag
- **Email metrics**: Send rate, bounces, complaints

## Documentation

Detailed documentation available for:
- Infrastructure setup and configuration
- DNS and email domain verification
- Secrets management strategy
- Monitoring and alerting setup
- Troubleshooting common issues

## Technical Decisions

This implementation demonstrates several architectural patterns:

- **Container orchestration** with ECS Fargate for operational simplicity
- **Managed services** (RDS, ElastiCache) for reduced operational overhead
- **Infrastructure as Code** for reproducibility and version control
- **Modular design** for reusability across environments
- **Security-first approach** with encryption and least-privilege access
- **Comprehensive monitoring** for operational visibility
