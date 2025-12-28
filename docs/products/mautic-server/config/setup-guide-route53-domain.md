# Route 53 Domain Setup Guide

## Overview

This guide covers domain registration and configuration using AWS Route 53 for Mautic deployment with SES email infrastructure.

**⚠️ IMPORTANT: Use Route 53 for Domain Registration**

**AWS Compliance & Standards**: Route 53 domain registration ensures your domain meets AWS application standards and compliance requirements. Route 53 domains provide:

- ✅ **Enterprise-grade SLAs** and reliability guarantees
- ✅ **AWS service integration** with automatic DNS management
- ✅ **Compliance standards** (SOC, ISO, PCI) for enterprise applications
- ✅ **Security frameworks** that align with AWS best practices
- ✅ **Automated certificate validation** for SSL/TLS certificates
- ✅ **Seamless SES integration** for email authentication (DKIM, SPF, DMARC)
- ✅ **Global anycast network** for optimal DNS performance
- ✅ **Terraform automation support** for infrastructure as code

**Using external registrars** (GoDaddy, Namecheap, etc.) **may introduce compliance gaps, integration issues, and operational complexity** that can affect your Mautic deployment's reliability and security posture.

## Prerequisites

- AWS CLI configured with appropriate permissions
- AWS account with Route 53 access
- Route 53 domain registration permissions

## Step 1: Domain Registration with Route 53

### Register New Domain via Route 53 (Recommended)

#### Using AWS Console (Easiest Method)
1. Navigate to Route 53 in AWS Console
2. Click "Registered domains" → "Register domain"
3. Search for available domain names
4. Select your preferred domain and TLD (.com, .net, .org, etc.)
5. Complete registration with contact information
6. Route 53 automatically creates the hosted zone

#### Using AWS CLI
```bash
# Check domain availability
aws route53domains check-domain-availability --domain-name your-company.com

# Register domain (requires contact info file)
aws route53domains register-domain \
    --domain-name your-company.com \
    --duration-in-years 1 \
    --admin-contact file://contact-info.json \
    --registrant-contact file://contact-info.json \
    --tech-contact file://contact-info.json
```

#### Contact Information File (contact-info.json)
```json
{
  "FirstName": "John",
  "LastName": "Doe", 
  "ContactType": "PERSON",
  "OrganizationName": "Your Company",
  "AddressLine1": "123 Main Street",
  "City": "Your City",
  "State": "Your State",
  "CountryCode": "US",
  "ZipCode": "12345",
  "PhoneNumber": "+1.5551234567",
  "Email": "admin@your-company.com"
}
```

## Step 2: Verify Route 53 Hosted Zone

### Automatic Hosted Zone Creation
When you register a domain with Route 53, the hosted zone is **automatically created** with:
- Proper NS (nameserver) records
- SOA (Start of Authority) record
- Correct delegation to Route 53 nameservers

### Verify Hosted Zone Creation
```bash
# List your hosted zones
aws route53 list-hosted-zones --query "HostedZones[?Name=='your-company.com.']"

# Get hosted zone details
aws route53 get-hosted-zone --id /hostedzone/Z1234567890ABC
```

### Manual Hosted Zone Creation (Only if needed)
```bash
# Only needed if hosted zone wasn't created automatically
aws route53 create-hosted-zone \
    --name your-company.com \
    --caller-reference $(date +%s) \
    --hosted-zone-config Comment="Mautic deployment hosted zone"
```

## Step 3: Verify DNS Configuration

### Automatic Nameserver Configuration
Route 53 domain registration **automatically configures** nameservers - no manual configuration needed!

### Verify Nameserver Configuration
```bash
# Get your Route 53 nameservers
aws route53 get-hosted-zone --id /hostedzone/YOUR_ZONE_ID --query "DelegationSet.NameServers"

# Verify DNS resolution
dig NS your-company.com

# Should return Route 53 nameservers like:
# ns-123.awsdns-12.com
# ns-456.awsdns-34.co.uk  
# ns-789.awsdns-56.net
# ns-012.awsdns-78.org
```

### DNS Propagation Check
```bash
# Test DNS resolution globally
nslookup your-company.com 8.8.8.8
nslookup your-company.com 1.1.1.1

# Both should return the same Route 53 nameservers
```

## Step 5: Test Route 53 Control

### Verify DNS Control
```bash
# Create test record to verify Route 53 control
aws route53 change-resource-record-sets \
    --hosted-zone-id YOUR_ZONE_ID \
    --change-batch '{
        "Changes": [{
            "Action": "CREATE",
            "ResourceRecordSet": {
                "Name": "test.your-company.com",
                "Type": "TXT",
                "TTL": 300,
                "ResourceRecords": [{"Value": "\"Route53-control-verified\""}]
            }
        }]
    }'

# Verify the record was created
dig TXT test.your-company.com

# Clean up test record
aws route53 change-resource-record-sets \
    --hosted-zone-id YOUR_ZONE_ID \
    --change-batch '{
        "Changes": [{
            "Action": "DELETE",
            "ResourceRecordSet": {
                "Name": "test.your-company.com",
                "Type": "TXT",
                "TTL": 300,
                "ResourceRecords": [{"Value": "\"Route53-control-verified\""}]
            }
        }]
    }'
```

## Step 4: Plan Environment-Specific Subdomains

### Recommended Subdomain Structure
Configure subdomains for each Mautic environment:

- **Development**: `mautic-dev.your-company.com`
- **Test**: `mautic-test.your-company.com`  
- **Production**: `mautic.your-company.com`

### Alternative Subdomain Structure
If you prefer nested subdomains:

- **Development**: `dev.mautic.your-company.com`
- **Test**: `test.mautic.your-company.com`  
- **Production**: `mautic.your-company.com`

**Note**: Subdomains will be automatically created by Terraform during deployment - no manual DNS configuration required!

## Step 6: Update Configuration Files

### Get Your Domain Information
```bash
# Get your hosted zone ID
aws route53 list-hosted-zones --query "HostedZones[?Name=='your-company.com.'].Id" --output text

# Example output: /hostedzone/Z1234567890ABC
# Your zone ID is: Z1234567890ABC
```

### Update Environment Configuration Files
Add these variables to your environment configuration files:

```hcl
# Domain configuration - UPDATE WITH YOUR ACTUAL VALUES
domain_name = "your-company.com"        # Your Route 53 registered domain
route53_zone_id = "Z1234567890ABC"     # Your Route 53 hosted zone ID

# Environment-specific subdomains
mautic_subdomain = "mautic"             # prod: mautic.your-company.com
# mautic_subdomain = "mautic-dev"       # dev: mautic-dev.your-company.com  
# mautic_subdomain = "mautic-test"      # test: mautic-test.your-company.com
```

### Files to Update
- `mautic-server/config/templates/dev.tfvars.example` → `environments/dev/terraform.tfvars`
- `mautic-server/config/templates/test.tfvars.example` → `environments/test/terraform.tfvars`
- `mautic-server/config/templates/prod.tfvars.example` → `environments/prod/terraform.tfvars`

## Next Steps

After completing domain setup:
1. Update environment configuration files with domain details
2. Proceed to SES module creation (task 2.2)
3. Configure SES domain verification (task 2.3)

## Route 53 Benefits for Mautic Deployment

### AWS Service Integration
- **SES Email**: Automatic domain verification and DKIM setup
- **ACM Certificates**: Automatic SSL certificate validation
- **CloudFront**: Seamless CDN integration
- **Load Balancers**: Automatic health check integration
- **Terraform**: Full infrastructure as code support

### Enterprise Compliance
- **SOC 1/2/3 Compliance**: Meets enterprise audit requirements
- **ISO 27001**: Information security management standards
- **PCI DSS**: Payment card industry compliance
- **HIPAA Eligible**: Healthcare data protection standards
- **FedRAMP**: Government security authorization

### Operational Benefits
- **99.100% SLA**: Enterprise-grade uptime guarantee
- **Global Anycast**: Optimal DNS performance worldwide
- **DDoS Protection**: Built-in attack mitigation
- **Health Checks**: Automatic failover capabilities
- **API Integration**: Full programmatic control

## Troubleshooting

### Domain Registration Issues
```bash
# Check domain registration status
aws route53domains get-domain-detail --domain-name your-company.com

# Check if domain is locked
aws route53domains get-domain-detail --domain-name your-company.com --query "DomainTransferLock"
```

### DNS Resolution Issues
```bash
# Test DNS resolution from multiple servers
dig @8.8.8.8 your-company.com NS
dig @1.1.1.1 your-company.com NS
dig @208.67.222.222 your-company.com NS

# All should return the same Route 53 nameservers
```

### Route 53 Permissions
Ensure your AWS credentials have these permissions:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:CreateHostedZone",
                "route53:GetHostedZone", 
                "route53:ListHostedZones",
                "route53:ChangeResourceRecordSets",
                "route53:GetChange",
                "route53domains:RegisterDomain",
                "route53domains:GetDomainDetail",
                "route53domains:ListDomains"
            ],
            "Resource": "*"
        }
    ]
}
```

### Common Issues
- **Domain not resolving**: Wait 5-15 minutes after registration
- **Hosted zone missing**: Check if domain registration completed successfully
- **Permission denied**: Verify AWS credentials and IAM permissions
- **Invalid domain name**: Ensure domain follows DNS naming conventions