# Basic Mautic Deployment Example

This example demonstrates a minimal Mautic deployment using the public modules. It creates a complete infrastructure stack suitable for development or testing environments.

## Architecture

This example deploys:

- **VPC** with public and private subnets across 2 AZs
- **RDS MySQL** database in private subnets with encryption
- **ECS Fargate** cluster for container orchestration
- **Application Load Balancer** for traffic distribution
- **Mautic service** running in ECS with proper configuration
- **CloudWatch** monitoring and logging

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. SSL certificate in AWS Certificate Manager (optional, for HTTPS)

## Quick Start

1. **Clone and navigate to the example:**
   ```bash
   cd examples/basic-setup
   ```

2. **Create a terraform.tfvars file:**
   ```hcl
   project_name = "my-mautic"
   environment  = "dev"
   aws_region   = "us-east-1"
   
   # Database configuration
   db_password = "your-secure-database-password"
   
   # Mautic configuration
   mautic_secret_key = "your-mautic-secret-key"
   trusted_hosts     = "yourdomain.com,www.yourdomain.com"
   
   # Optional: SSL certificate for HTTPS
   ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
   
   # Optional: Enable monitoring alerts
   enable_monitoring_alerts = true
   ```

3. **Initialize and apply Terraform:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Access your Mautic installation:**
   After deployment, use the `mautic_url` output to access your Mautic instance.

## Configuration

### Required Variables

- `db_password`: Secure password for the MySQL database
- `mautic_secret_key`: Secret key for Mautic application security

### Optional Customization

- `vpc_cidr`: Change the VPC CIDR block (default: 10.0.0.0/16)
- `db_instance_class`: RDS instance size (default: db.t3.micro)
- `task_cpu`/`task_memory`: ECS task resources
- `desired_count`: Number of Mautic containers to run
- `ssl_certificate_arn`: Enable HTTPS with your SSL certificate

## Outputs

After deployment, you'll receive:

- `mautic_url`: Direct URL to access your Mautic installation
- `load_balancer_dns_name`: Load balancer endpoint
- `cloudwatch_dashboard_url`: Monitoring dashboard
- Network and service information for further customization

## Security Features

This example includes:

- **Private networking**: Database and application in private subnets
- **Encryption**: RDS encryption at rest enabled
- **Secrets management**: Database passwords stored in AWS Secrets Manager
- **Security groups**: Restrictive network access rules
- **IAM roles**: Least-privilege permissions for ECS tasks

## Monitoring

The deployment includes:

- CloudWatch log groups for container logs
- Dashboard with key metrics (CPU, memory, response times)
- Optional CloudWatch alarms for proactive monitoring
- SNS topic for alert notifications

## Cost Optimization

For development environments:

- Uses `db.t3.micro` RDS instance (free tier eligible)
- Single NAT Gateway for cost savings
- Fargate Spot can be enabled for additional savings

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Note**: Ensure you have backups of any important data before destroying the infrastructure.

## Next Steps

After successful deployment:

1. **Complete Mautic setup**: Access the Mautic URL and follow the installation wizard
2. **Configure DNS**: Point your domain to the load balancer DNS name
3. **Set up monitoring**: Configure SNS notifications for alerts
4. **Backup strategy**: Implement regular database backups
5. **Security hardening**: Review and adjust security groups as needed

## Troubleshooting

### Common Issues

1. **ECS tasks not starting**: Check CloudWatch logs for container errors
2. **Database connection issues**: Verify security group rules and credentials
3. **Load balancer health checks failing**: Ensure Mautic is responding on the correct port

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster <cluster-name> --services <service-name>

# View container logs
aws logs tail /ecs/<project-name>-<environment> --follow

# Test database connectivity
aws rds describe-db-instances --db-instance-identifier <db-identifier>
```

## Support

For issues specific to this example:

1. Check the Terraform plan output for resource conflicts
2. Review AWS CloudWatch logs for application errors
3. Verify all required variables are properly set
4. Ensure AWS credentials have sufficient permissions