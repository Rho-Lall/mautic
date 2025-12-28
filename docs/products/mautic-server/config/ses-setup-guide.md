# SES Setup and Domain Verification Guide

## Overview

This guide walks through setting up AWS Simple Email Service (SES) for Mautic email infrastructure, including domain verification, DKIM, SPF, and DMARC configuration.

## Prerequisites

- Domain registered and Route 53 hosted zone configured (see `domain-setup.md`)
- AWS CLI configured with appropriate permissions
- Terraform installed and configured

## Step-by-Step Setup

### Step 1: Prepare Domain Configuration

1. **Ensure domain is configured in Route 53**:
   ```bash
   # Verify hosted zone exists
   aws route53 list-hosted-zones --query "HostedZones[?Name=='yourdomain.com.']"
   ```

2. **Update environment configuration**:
   - Edit `mautic-server/config/templates/{env}.tfvars.example`
   - Set `domain_name` and `route53_zone_id`
   - Configure SES-specific variables

### Step 2: Deploy SES Module

1. **Copy SES example configuration**:
   ```bash
   # For development environment
   cp mautic-server/terraform/environments/dev/ses-example.tf \
      mautic-server/terraform/environments/dev/ses.tf
   ```

2. **Update variables in your main Terraform configuration**:
   ```hcl
   # Add to variables.tf
   variable "domain_name" {
     description = "Domain name for SES configuration"
     type        = string
   }
   
   variable "route53_zone_id" {
     description = "Route 53 hosted zone ID"
     type        = string
   }
   
   variable "ses_configuration_set_name" {
     description = "SES configuration set name"
     type        = string
   }
   ```

3. **Deploy the SES module**:
   ```bash
   cd mautic-server/terraform/environments/dev
   terraform init
   terraform plan -var-file="../../config/dev.tfvars"
   terraform apply -var-file="../../config/dev.tfvars"
   ```

### Step 3: Verify Domain Setup

1. **Run the verification script**:
   ```bash
   ./mautic-server/scripts/verify-ses-domain.sh -e dev -d yourdomain.com
   ```

2. **Check DNS propagation**:
   ```bash
   # Check SES verification record
   dig TXT _amazonses.yourdomain.com
   
   # Check DKIM records
   dig CNAME token1._domainkey.yourdomain.com
   dig CNAME token2._domainkey.yourdomain.com
   dig CNAME token3._domainkey.yourdomain.com
   
   # Check SPF record
   dig TXT yourdomain.com | grep spf1
   
   # Check DMARC record (if enabled)
   dig TXT _dmarc.yourdomain.com
   ```

### Step 4: Test Email Sending

1. **Development Environment (Sandbox Mode)**:
   ```bash
   # Add verified email addresses in SES console
   aws ses verify-email-identity --email-address test@yourdomain.com
   
   # Send test email
   aws ses send-email \
     --source test@yourdomain.com \
     --destination ToAddresses=test@yourdomain.com \
     --message Subject={Data="Test Email"},Body={Text={Data="This is a test email"}}
   ```

2. **Test/Production Environment**:
   - Request production access through SES console
   - Test with external email addresses
   - Monitor bounce and complaint rates

### Step 5: Configure Mautic Integration

1. **Retrieve SMTP credentials from Secrets Manager**:
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id mautic-server-dev-ses-smtp \
     --query SecretString --output text | jq .
   ```

2. **Configure Mautic email settings**:
   - SMTP Host: `email-smtp.us-east-1.amazonaws.com`
   - SMTP Port: `587`
   - SMTP Username: From secrets manager
   - SMTP Password: From secrets manager
   - Configuration Set: `mautic-{environment}-config-set`

## Environment-Specific Configurations

### Development Environment

```hcl
# Development SES configuration
module "ses" {
  source = "../../modules/ses"
  
  domain_name            = "yourdomain.com"
  route53_zone_id       = "Z1234567890ABC"
  environment           = "dev"
  configuration_set_name = "mautic-dev-config-set"
  
  # Development settings
  sending_enabled = false  # Sandbox mode
  enable_dmarc   = false   # Skip DMARC for dev
  log_retention_days = 7
  
  authorized_from_addresses = [
    "dev-test@yourdomain.com",
    "noreply@yourdomain.com"
  ]
}
```

**Development Features**:
- Sandbox mode (can only send to verified addresses)
- Minimal logging retention
- No DMARC policy
- Basic monitoring

### Test Environment

```hcl
# Test SES configuration
module "ses" {
  source = "../../modules/ses"
  
  domain_name            = "yourdomain.com"
  route53_zone_id       = "Z1234567890ABC"
  environment           = "test"
  configuration_set_name = "mautic-test-config-set"
  
  # Test settings
  sending_enabled = true
  enable_dmarc   = true
  dmarc_policy   = "none"  # Monitoring mode
  log_retention_days = 14
  
  # Enhanced monitoring
  enable_bounce_notifications = true
  enable_complaint_notifications = true
}
```

**Test Features**:
- Production sending enabled
- DMARC in monitoring mode
- Bounce/complaint notifications
- Extended logging retention

### Production Environment

```hcl
# Production SES configuration
module "ses" {
  source = "../../modules/ses"
  
  domain_name            = "yourdomain.com"
  route53_zone_id       = "Z1234567890ABC"
  environment           = "prod"
  configuration_set_name = "mautic-prod-config-set"
  
  # Production settings
  sending_enabled = true
  enable_dmarc   = true
  dmarc_policy   = "quarantine"  # Strict policy
  log_retention_days = 30
  
  # Enhanced security and monitoring
  enable_sending_authorization = true
  enable_bounce_notifications = true
  enable_complaint_notifications = true
}
```

**Production Features**:
- Strict DMARC policy
- Enhanced security controls
- Comprehensive monitoring
- CloudWatch alarms
- Encrypted SNS notifications

## DNS Records Reference

The SES module automatically creates these DNS records:

### SES Verification Record
```
Name: _amazonses.yourdomain.com
Type: TXT
Value: [verification-token]
```

### DKIM Records (3 records)
```
Name: [token1]._domainkey.yourdomain.com
Type: CNAME
Value: [token1].dkim.amazonses.com

Name: [token2]._domainkey.yourdomain.com
Type: CNAME
Value: [token2].dkim.amazonses.com

Name: [token3]._domainkey.yourdomain.com
Type: CNAME
Value: [token3].dkim.amazonses.com
```

### SPF Record
```
Name: yourdomain.com
Type: TXT
Value: v=spf1 include:amazonses.com ~all
```

### DMARC Record (optional)
```
Name: _dmarc.yourdomain.com
Type: TXT
Value: v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@yourdomain.com; ruf=mailto:dmarc-forensic@yourdomain.com; fo=1
```

## Monitoring and Troubleshooting

### CloudWatch Metrics

Monitor these key SES metrics:
- **Send**: Total emails sent
- **Bounce**: Bounced emails
- **Complaint**: Spam complaints
- **Delivery**: Successfully delivered emails
- **Open**: Email opens (requires tracking)
- **Click**: Link clicks (requires tracking)
- **Reputation.BounceRate**: Bounce rate percentage
- **Reputation.ComplaintRate**: Complaint rate percentage

### CloudWatch Alarms

Production environment includes alarms for:
- High bounce rate (>5%)
- High complaint rate (>0.1%)

### Common Issues

1. **Domain Verification Fails**:
   - Check DNS propagation: `dig TXT _amazonses.yourdomain.com`
   - Verify Route 53 hosted zone is active
   - Ensure nameservers are correctly configured

2. **DKIM Verification Fails**:
   - Check all 3 DKIM CNAME records exist
   - Verify DNS propagation
   - Wait up to 72 hours for verification

3. **Emails Not Sending**:
   - Check if SES is in sandbox mode
   - Verify sender email is authorized
   - Check bounce/complaint rates
   - Review CloudWatch logs

4. **High Bounce/Complaint Rates**:
   - Review email list quality
   - Implement double opt-in
   - Monitor suppression lists
   - Review email content and frequency

### Verification Commands

```bash
# Check domain verification status
aws ses get-identity-verification-attributes --identities yourdomain.com

# Check DKIM status
aws ses get-identity-dkim-attributes --identities yourdomain.com

# Check sending quota and rate
aws ses get-send-quota

# Check sending statistics
aws ses get-send-statistics

# List suppressed addresses
aws sesv2 list-suppressed-destinations
```

## Security Best Practices

1. **Use IAM Roles**: Prefer IAM roles over access keys when possible
2. **Rotate SMTP Credentials**: Enable automatic rotation in Secrets Manager
3. **Monitor Sending**: Set up CloudWatch alarms for unusual activity
4. **Implement DMARC**: Use strict DMARC policy in production
5. **Encrypt Notifications**: Use KMS encryption for SNS topics
6. **Limit Authorized Senders**: Restrict who can send from your domain

## Next Steps

After completing SES setup:
1. Integrate SES configuration with Mautic deployment
2. Set up email templates and campaigns in Mautic
3. Configure bounce and complaint handling
4. Monitor email deliverability and reputation
5. Implement email authentication best practices

## Resources

- [AWS SES Developer Guide](https://docs.aws.amazon.com/ses/latest/dg/)
- [Email Authentication Best Practices](https://docs.aws.amazon.com/ses/latest/dg/send-email-authentication.html)
- [SES Sending Limits](https://docs.aws.amazon.com/ses/latest/dg/manage-sending-limits.html)
- [Mautic Email Configuration](https://docs.mautic.org/en/configuration/settings#email-settings)