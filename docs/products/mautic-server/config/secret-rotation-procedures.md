# Secret Rotation Procedures

This document outlines the procedures for rotating secrets in AWS Secrets Manager for Mautic server deployments.

## Overview

Regular secret rotation is a critical security practice that helps protect against credential compromise. This document provides step-by-step procedures for rotating different types of secrets used by the Mautic server.

## Rotation Schedule

### Recommended Rotation Frequency

- **Database passwords**: Every 90 days
- **Admin passwords**: Every 60 days  
- **API keys**: Every 90 days
- **Webhook secrets**: Every 90 days
- **SES SMTP credentials**: Every 180 days (coordinate with SES team)

### Emergency Rotation

Perform immediate rotation if:
- Credentials are suspected to be compromised
- A team member with access leaves the organization
- Security audit identifies credential exposure
- Automated security scanning detects issues

## Rotation Procedures

### 1. Automated Password Rotation

Use the secrets management script for automated password generation:

```bash
# Rotate all passwords for development environment
./scripts/manage-secrets.sh rotate dev

# Rotate all passwords for production environment  
./scripts/manage-secrets.sh rotate prod
```

This command will:
- Generate new secure passwords for database, admin, API keys, and webhook secrets
- Preserve all other configuration values
- Update the secret in AWS Secrets Manager
- Maintain the existing secret structure

### 2. Manual Selective Rotation

For rotating specific credentials manually:

#### Database Password Rotation

1. **Generate new password**:
   ```bash
   NEW_DB_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-24)
   echo "New database password: $NEW_DB_PASSWORD"
   ```

2. **Update secret in AWS Secrets Manager**:
   ```bash
   # Get current secret
   aws secretsmanager get-secret-value \
     --secret-id "mautic-prod-secrets" \
     --query SecretString --output text > current_secret.json
   
   # Update database password
   jq --arg new_pass "$NEW_DB_PASSWORD" \
     '.database_password = $new_pass' \
     current_secret.json > updated_secret.json
   
   # Update secret
   aws secretsmanager update-secret \
     --secret-id "mautic-prod-secrets" \
     --secret-string file://updated_secret.json
   
   # Clean up temporary files
   rm current_secret.json updated_secret.json
   ```

3. **Update RDS database** (if using RDS with master password):
   ```bash
   aws rds modify-db-instance \
     --db-instance-identifier "mautic-prod-database" \
     --master-user-password "$NEW_DB_PASSWORD" \
     --apply-immediately
   ```

4. **Restart Mautic service** to pick up new credentials:
   ```bash
   # Force ECS service update to restart tasks
   aws ecs update-service \
     --cluster "mautic-prod-cluster" \
     --service "mautic-prod-service" \
     --force-new-deployment
   ```

#### Admin Password Rotation

1. **Generate new admin password**:
   ```bash
   NEW_ADMIN_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
   ```

2. **Update secret**:
   ```bash
   # Update admin password in secret
   aws secretsmanager get-secret-value \
     --secret-id "mautic-prod-secrets" \
     --query SecretString --output text | \
   jq --arg new_pass "$NEW_ADMIN_PASSWORD" \
     '.admin_credentials.admin_password = $new_pass' | \
   aws secretsmanager update-secret \
     --secret-id "mautic-prod-secrets" \
     --secret-string file:///dev/stdin
   ```

3. **Update password in Mautic application**:
   - Log into Mautic admin interface
   - Navigate to Settings > Users
   - Update the admin user password
   - Or use Mautic CLI if available

#### API Key Rotation

1. **Generate new API key**:
   ```bash
   NEW_API_KEY=$(openssl rand -base64 40 | tr -d "=+/" | cut -c1-40)
   ```

2. **Update secret**:
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id "mautic-prod-secrets" \
     --query SecretString --output text | \
   jq --arg new_key "$NEW_API_KEY" \
     '.api_keys.mautic_api_key = $new_key' | \
   aws secretsmanager update-secret \
     --secret-id "mautic-prod-secrets" \
     --secret-string file:///dev/stdin
   ```

3. **Update API key in Mautic**:
   - Log into Mautic admin interface
   - Navigate to Settings > API Settings
   - Update or regenerate API credentials
   - Update any external integrations using the API

### 3. SES SMTP Credentials Rotation

SES SMTP credentials require special handling:

1. **Create new SMTP credentials in AWS SES**:
   ```bash
   # Create new SMTP user
   aws sesv2 create-dedicated-ip-pool --pool-name "mautic-smtp-pool"
   
   # Note: SMTP credentials are typically managed through IAM users
   # Create new IAM user for SMTP access
   aws iam create-user --user-name "mautic-smtp-user-$(date +%Y%m%d)"
   
   # Attach SES sending policy
   aws iam attach-user-policy \
     --user-name "mautic-smtp-user-$(date +%Y%m%d)" \
     --policy-arn "arn:aws:iam::aws:policy/AmazonSESFullAccess"
   
   # Create access keys
   aws iam create-access-key --user-name "mautic-smtp-user-$(date +%Y%m%d)"
   ```

2. **Update secret with new SMTP credentials**:
   ```bash
   # Update SMTP credentials in secret
   aws secretsmanager get-secret-value \
     --secret-id "mautic-prod-secrets" \
     --query SecretString --output text | \
   jq --arg smtp_user "$NEW_SMTP_USERNAME" \
      --arg smtp_pass "$NEW_SMTP_PASSWORD" \
     '.email_configuration.smtp_username = $smtp_user |
      .email_configuration.smtp_password = $smtp_pass' | \
   aws secretsmanager update-secret \
     --secret-id "mautic-prod-secrets" \
     --secret-string file:///dev/stdin
   ```

3. **Test email sending** before removing old credentials

4. **Remove old SMTP credentials**:
   ```bash
   # Delete old IAM user and access keys
   aws iam delete-access-key --user-name "old-smtp-user" --access-key-id "OLD_ACCESS_KEY"
   aws iam detach-user-policy --user-name "old-smtp-user" --policy-arn "arn:aws:iam::aws:policy/AmazonSESFullAccess"
   aws iam delete-user --user-name "old-smtp-user"
   ```

## Post-Rotation Procedures

### 1. Validation

After any rotation, validate the changes:

```bash
# Validate secret structure
./scripts/manage-secrets.sh validate prod

# Run full deployment validation
./scripts/validate.sh prod

# Test application functionality
./scripts/verify.sh prod
```

### 2. Service Restart

Most credential changes require service restart:

```bash
# Restart Mautic ECS service
aws ecs update-service \
  --cluster "mautic-prod-cluster" \
  --service "mautic-prod-service" \
  --force-new-deployment

# Monitor service health
aws ecs describe-services \
  --cluster "mautic-prod-cluster" \
  --services "mautic-prod-service"
```

### 3. Monitoring

Monitor application logs after rotation:

```bash
# Check ECS task logs
aws logs tail /aws/ecs/mautic-prod --follow

# Check application health
curl -f https://mautic.yourdomain.com/health || echo "Health check failed"
```

### 4. Documentation

Document the rotation:

- Update rotation log with date, rotated credentials, and performed by
- Notify team members of credential changes
- Update any external documentation or runbooks

## Troubleshooting

### Common Issues

#### Service Won't Start After Rotation

1. **Check secret format**:
   ```bash
   ./scripts/manage-secrets.sh validate prod
   ```

2. **Verify ECS task definition**:
   ```bash
   aws ecs describe-task-definition --task-definition mautic-prod
   ```

3. **Check ECS service events**:
   ```bash
   aws ecs describe-services --cluster mautic-prod-cluster --services mautic-prod-service
   ```

#### Database Connection Failures

1. **Verify RDS password was updated**:
   ```bash
   aws rds describe-db-instances --db-instance-identifier mautic-prod-database
   ```

2. **Check database connectivity**:
   ```bash
   # Test from ECS task or EC2 instance
   mysql -h database-endpoint -u mautic_user -p
   ```

#### Email Sending Failures

1. **Verify SES SMTP credentials**:
   ```bash
   # Test SMTP connection
   openssl s_client -connect email-smtp.us-east-1.amazonaws.com:587 -starttls smtp
   ```

2. **Check SES sending statistics**:
   ```bash
   aws ses get-send-statistics
   ```

### Recovery Procedures

#### Rollback to Previous Credentials

If rotation causes issues, rollback using previous secret version:

```bash
# List secret versions
aws secretsmanager list-secret-version-ids --secret-id "mautic-prod-secrets"

# Restore previous version
aws secretsmanager restore-secret \
  --secret-id "mautic-prod-secrets" \
  --version-id "PREVIOUS_VERSION_ID"
```

#### Emergency Access

If admin credentials are lost:

1. **Reset via database**:
   ```sql
   -- Connect to database directly
   UPDATE users SET password = MD5('new_temp_password') WHERE username = 'admin';
   ```

2. **Use Mautic CLI** (if available):
   ```bash
   # Reset admin password
   php bin/console mautic:user:password admin new_password
   ```

## Automation

### Scheduled Rotation

Consider setting up automated rotation using AWS Lambda:

```bash
# Create Lambda function for automated rotation
aws lambda create-function \
  --function-name "mautic-secret-rotation" \
  --runtime "python3.9" \
  --role "arn:aws:iam::ACCOUNT:role/lambda-secrets-rotation-role" \
  --handler "lambda_function.lambda_handler" \
  --zip-file "fileb://rotation-function.zip"

# Schedule rotation every 90 days
aws events put-rule \
  --name "mautic-secret-rotation-schedule" \
  --schedule-expression "rate(90 days)"
```

### Monitoring and Alerting

Set up CloudWatch alarms for rotation events:

```bash
# Create alarm for failed rotations
aws cloudwatch put-metric-alarm \
  --alarm-name "mautic-secret-rotation-failures" \
  --alarm-description "Alert on secret rotation failures" \
  --metric-name "RotationFailed" \
  --namespace "AWS/SecretsManager" \
  --statistic "Sum" \
  --period 300 \
  --threshold 1 \
  --comparison-operator "GreaterThanOrEqualToThreshold"
```

## Security Considerations

### Access Control

- Limit who can perform rotations using IAM policies
- Use MFA for production secret rotations
- Log all rotation activities in CloudTrail
- Implement approval workflows for production changes

### Audit Trail

- Maintain rotation logs with timestamps and operators
- Monitor secret access patterns
- Set up alerts for unusual access patterns
- Regular security reviews of rotation procedures

### Best Practices

- Test rotation procedures in development first
- Coordinate rotations with maintenance windows
- Have rollback procedures ready
- Document all custom rotation requirements
- Regular training for operations team