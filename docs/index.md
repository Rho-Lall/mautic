# Mautic Marketing Automation Suite

A production-ready marketing automation platform demonstrating modern cloud architecture patterns, infrastructure as code, and DevOps best practices.

## 🎯 Project Overview

This repository showcases the design and implementation of a multi-component marketing automation system built on AWS, featuring:

- **Serverless lead capture** with embeddable forms
- **Self-hosted Mautic server** on ECS with RDS and ElastiCache
- **Email infrastructure** using AWS SES with custom domain configuration
- **Security management** framework for secrets and configuration
- **Infrastructure as Code** using Terraform with modular design
- **Multi-environment support** (dev, test, production)

## 🏗️ Architecture

The system demonstrates a hybrid cloud architecture combining serverless and container-based components:

```
┌─────────────────────┐
│  Static Websites    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────┐
│  Serverless Lead Capture    │
│  • API Gateway + Lambda     │
│  • DynamoDB                 │
│  • CloudWatch Monitoring    │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│  Mautic Server (ECS)        │
│  • Docker containers        │
│  • RDS MySQL                │
│  • ElastiCache Redis        │
│  • Application Load Balancer│
│  • SES Email Integration    │
└─────────────────────────────┘
```

## 🔧 Technical Highlights

### Infrastructure as Code
- **Terraform modules** for reusable infrastructure components
- **Environment separation** with shared backend state management
- **Property-based testing** using Hypothesis for infrastructure validation
- **Security-first design** with least-privilege IAM policies

### Serverless Components
- **API Gateway** with CORS, rate limiting, and request validation
- **Lambda functions** for form processing and data retrieval
- **DynamoDB** with encryption at rest and point-in-time recovery
- **CloudWatch** dashboards and alarms for monitoring

### Container Orchestration
- **ECS Fargate** for serverless container management
- **Multi-AZ RDS** with automated backups and encryption
- **ElastiCache** for session management and caching
- **ALB** with SSL termination and health checks

### Email Infrastructure
- **AWS SES** with custom domain configuration
- **DNS management** via Route 53 with DKIM, SPF, and DMARC
- **SMTP integration** for Mautic email campaigns
- **Monitoring and alerting** for bounce and complaint rates

## 📁 Repository Structure

```
├── serverless/              # Serverless lead capture
│   └── lead-capture/
│       ├── terraform/       # Infrastructure modules
│       └── src/             # Lambda functions and client code
├── mautic-server/           # Self-hosted Mautic
│   ├── terraform/
│   │   ├── modules/         # Reusable infrastructure modules
│   │   ├── environments/    # Environment-specific configs
│   │   └── tests/           # Property-based infrastructure tests
│   ├── docker/              # Container configurations
│   └── scripts/             # Deployment and validation scripts
└── docs/                    # Comprehensive documentation
    ├── installation-guides/ # Setup and configuration
    ├── products/            # Product-specific docs
    └── reference/           # Architecture and design decisions
```

## 🔍 Key Features

### Security & Compliance
- Encryption at rest and in transit
- IAM least-privilege policies
- VPC isolation with security groups
- [Secrets management](products/security-management/secrets-management.md) via AWS Secrets Manager
- Comprehensive audit logging

### Monitoring & Observability
- CloudWatch dashboards for all components
- Custom metrics and alarms
- SES email monitoring (bounces, complaints)
- Infrastructure health checks
- Cost tracking and optimization

### DevOps Practices
- Infrastructure as Code (Terraform)
- Modular, reusable components
- Environment parity (dev/test/prod)
- Automated testing and validation
- Documentation-driven development

## 📚 Documentation

Explore the technical implementation:

- **[Architecture Overview](architecture.md)** - System design and component interactions
- **[Serverless Lead Capture](products/serverless/overview.md)** - API Gateway, Lambda, and DynamoDB implementation
- **[Mautic Server](products/mautic-server/overview.md)** - ECS, RDS, and email integration details
- **[Simple Email Service](products/simple-email-service/overview.md)** - Reusable SES Terraform module
- **[Security Management](products/security-management/overview.md)** - Secrets and configuration management framework
- **[Getting Started](getting-started/getting-started.md)** - Setup prerequisites and deployment walkthrough

## 🛠️ Technologies Used

**Cloud Platform:** AWS (Lambda, API Gateway, DynamoDB, ECS, RDS, ElastiCache, SES, Route 53, CloudWatch)

**Infrastructure:** Terraform, Docker

**Languages:** JavaScript (Node.js), Python, HCL

**Testing:** Hypothesis (property-based testing), pytest

**Monitoring:** CloudWatch, AWS X-Ray

## 💡 Design Decisions

This project demonstrates several architectural patterns and best practices:

- **Hybrid architecture** balancing serverless and container-based workloads
- **Modular Terraform design** for reusability and maintainability
- **Multi-environment strategy** with shared state management
- **Security-first approach** with encryption and least-privilege access
- **Comprehensive monitoring** for operational excellence
- **Cost optimization** through appropriate service selection

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
