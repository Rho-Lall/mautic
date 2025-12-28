# Serverless Lead Capture

A serverless lead capture system demonstrating event-driven architecture with API Gateway, Lambda, and DynamoDB for embeddable form processing.

## Overview

This implementation showcases a fully serverless approach to form handling, designed to be embedded in static websites while maintaining security, scalability, and cost efficiency.

## Architecture

```
Client Browser
    ↓
API Gateway (REST API)
    ↓
Lambda Functions
    ↓
DynamoDB
    ↓
CloudWatch (Monitoring)
```

## Infrastructure Components

### API Gateway
- **REST API**: Resource-based routing with CORS configuration
- **Request validation**: Gateway-level input validation
- **API key authentication**: Protected endpoints with usage plans
- **Rate limiting**: Throttling and quota management
- **Access logging**: CloudWatch integration for request tracking

### Lambda Functions
- **submit-lead**: Processes POST requests, validates input, writes to DynamoDB
- **get-leads**: Retrieves lead data with query parameter support
- **Node.js 18.x runtime**: 256MB memory, 30-second timeout
- **Environment-based configuration**: Externalized settings
- **IAM roles**: Least-privilege permissions

### DynamoDB
- **Single table design**: Partition key (leadId), sort key (timestamp)
- **On-demand billing**: Pay-per-request pricing model
- **Point-in-time recovery**: Backup and restore capabilities
- **Encryption at rest**: AWS managed keys
- **Optional TTL**: Automatic data expiration

### Client Integration
- **Vanilla JavaScript**: No framework dependencies
- **Progressive enhancement**: Works without JavaScript
- **Responsive CSS**: Mobile-optimized styling
- **Accessibility compliant**: WCAG 2.1 standards

## Terraform Modules

The infrastructure is organized into reusable Terraform modules:

```
terraform/modules/
├── api-gateway/       # REST API and CORS configuration
├── lambda/            # Function definitions and IAM roles
├── dynamodb/          # Table configuration and indexes
└── monitoring/        # CloudWatch dashboards and alarms
```

## Key Features

### Security
- **CORS restrictions**: Domain-specific access control
- **Input validation**: Server-side sanitization and type checking
- **HTTPS enforcement**: TLS 1.2+ required
- **IAM policies**: Least-privilege access throughout
- **Encryption**: At rest (DynamoDB) and in transit (TLS)

### Monitoring & Observability
- **CloudWatch dashboards**: Request rates, latency, error rates
- **Custom alarms**: High error rate, Lambda timeouts, throttling
- **Structured logging**: JSON logs with correlation IDs
- **Performance metrics**: Cold start tracking, execution duration

### Cost Optimization
- **On-demand billing**: No provisioned capacity
- **Lambda optimization**: Right-sized memory allocation
- **Free tier eligible**: 1M Lambda requests/month
- **Estimated cost**: <$5/month for 1,000 submissions

## Performance Characteristics

### Latency
- **Cold start**: 200-500ms (first request)
- **Warm execution**: 50-100ms
- **Total response time**: 100-200ms (warm)

### Scalability
- **Concurrent executions**: 1,000 (default Lambda limit)
- **API Gateway**: 10,000 requests/second
- **DynamoDB**: Unlimited with on-demand
- **Automatic scaling**: No configuration required

### Reliability
- **Multi-AZ deployment**: Built-in by AWS
- **Lambda SLA**: 99.95% availability
- **DynamoDB SLA**: 99.99% availability
- **Automatic failover**: Managed by AWS

## Testing

### Infrastructure Testing
Property-based testing using Hypothesis and pytest:
- API Gateway configuration validation
- Lambda IAM policy verification
- DynamoDB table structure testing
- CORS policy compliance

### Integration Testing
- End-to-end request flow validation
- Error handling and response formats
- Authentication mechanisms
- Rate limiting behavior

## Deployment

### Multi-Environment Strategy
- **Development**: Relaxed CORS, debug logging, minimal resources
- **Production**: Strict CORS, production logging, monitoring enabled

### Environment Variables
```bash
DYNAMODB_TABLE_NAME=leads-table
CORS_ALLOW_ORIGIN=https://yourdomain.com
LOG_LEVEL=info
ENVIRONMENT=production
```

## Technical Decisions

This implementation demonstrates several serverless patterns:

- **Event-driven architecture** with API Gateway triggers
- **Stateless functions** for horizontal scalability
- **Managed services** for reduced operational overhead
- **Pay-per-use pricing** for cost efficiency
- **Infrastructure as Code** for reproducibility
- **Security-first design** with multiple protection layers
