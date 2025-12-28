# Simple Email Service Module

A production-ready Terraform module for AWS Simple Email Service (SES), providing domain verification, DKIM authentication, email templates, bounce handling, and comprehensive monitoring.

## Overview

This Terraform module creates a complete AWS SES infrastructure for sending transactional and marketing emails. It handles domain verification, DKIM setup, bounce/complaint management, CloudWatch monitoring, and IAM permissions.

## Features

- **Domain and Email Verification**: Verify domains and individual email addresses
- **DKIM Authentication**: Domain-based message authentication
- **Email Templates**: Pre-configured templates for notifications
- **Bounce Handling**: SNS integration for bounce and complaint management
- **CloudWatch Integration**: Logging and monitoring of email events
- **IAM Roles**: Secure sending permissions for Lambda functions
- **Configuration Sets**: Organized email sending with reputation tracking

## Usage

### Basic Email Sending

```hcl
module "ses" {
  source = "./modules/ses"

  # Email addresses to verify
  sender_emails = ["noreply@example.com", "admin@example.com"]
  
  configuration_set_name = "lead-capture-emails"
  
  # Basic monitoring
  enable_monitoring         = true
  enable_cloudwatch_logging = true

  tags = {
    Environment = "production"
    Project     = "lead-capture"
  }
}
```

### Domain-based Configuration

```hcl
module "ses" {
  source = "./modules/ses"

  # Domain verification
  domain_name      = "example.com"
  mail_from_domain = "mail.example.com"
  
  # Individual sender emails
  sender_emails = ["noreply@example.com"]
  
  configuration_set_name = "lead-capture-emails"
  
  # DKIM authentication
  enable_dkim = true
  
  # Bounce and complaint handling
  enable_bounce_handling = true
  
  # Monitoring and logging
  enable_monitoring         = true
  enable_cloudwatch_logging = true
  bounce_rate_threshold     = 3.0
  complaint_rate_threshold  = 0.3

  tags = {
    Environment = "production"
    Project     = "lead-capture"
  }
}
```

### Complete Configuration with Templates

```hcl
module "ses" {
  source = "./modules/ses"

  # Domain and email setup
  domain_name      = "example.com"
  sender_emails    = ["noreply@example.com", "support@example.com"]
  mail_from_domain = "mail.example.com"
  
  configuration_set_name = "lead-capture-emails"
  
  # Authentication and security
  enable_dkim                = true
  enable_reputation_metrics  = true
  
  # Bounce and complaint handling
  enable_bounce_handling = true
  
  # Email templates
  lead_notification_subject = "New Lead: {{name}} from {{source}}"
  enable_welcome_email      = true
  welcome_email_subject     = "Welcome {{name}}! Thanks for your interest"
  
  # IAM role for Lambda integration
  create_sending_role = true
  
  # Monitoring
  enable_monitoring         = true
  enable_cloudwatch_logging = true
  bounce_rate_threshold     = 2.0
  complaint_rate_threshold  = 0.2
  log_retention_days        = 30

  tags = {
    Environment = "production"
    Project     = "lead-capture"
    Owner       = "marketing-team"
  }
}
```

## Variables

### Required Variables

None - all variables have sensible defaults.

### Optional Variables

| Name | Description | Type | Default | Validation |
|------|-------------|------|---------|------------|
| `domain_name` | Domain name to verify with SES (optional) | `string` | `""` | - |
| `sender_emails` | List of email addresses to verify with SES | `list(string)` | `[]` | Valid email format |
| `configuration_set_name` | Name of the SES configuration set | `string` | `"lead-capture-config-set"` | - |
| `enable_dkim` | Enable DKIM signing for the domain | `bool` | `true` | - |
| `mail_from_domain` | Custom MAIL FROM domain (optional) | `string` | `""` | - |
| `enable_reputation_metrics` | Enable reputation metrics | `bool` | `true` | - |
| `enable_bounce_handling` | Enable bounce and complaint handling via SNS | `bool` | `true` | - |
| `enable_cloudwatch_logging` | Enable CloudWatch logging for SES events | `bool` | `true` | - |
| `log_retention_days` | CloudWatch log retention in days | `number` | `14` | Valid retention period |
| `enable_monitoring` | Enable CloudWatch monitoring and alarms | `bool` | `true` | - |
| `bounce_rate_threshold` | Bounce rate threshold for alarms (%) | `number` | `5.0` | Between 0 and 100 |
| `complaint_rate_threshold` | Complaint rate threshold for alarms (%) | `number` | `0.5` | Between 0 and 100 |
| `create_sending_role` | Create IAM role for SES sending | `bool` | `false` | - |
| `lead_notification_template_name` | Name of lead notification template | `string` | `"lead-notification"` | - |
| `lead_notification_subject` | Subject for lead notification emails | `string` | `"New Lead Captured: {{name}}"` | - |
| `lead_notification_html_template` | HTML template for notifications | `string` | Default template | - |
| `lead_notification_text_template` | Text template for notifications | `string` | Default template | - |
| `enable_welcome_email` | Enable welcome email template | `bool` | `false` | - |
| `welcome_email_template_name` | Name of welcome email template | `string` | `"welcome-email"` | - |
| `welcome_email_subject` | Subject for welcome emails | `string` | `"Welcome! Thank you for your interest"` | - |
| `welcome_email_html_template` | HTML template for welcome emails | `string` | Default template | - |
| `welcome_email_text_template` | Text template for welcome emails | `string` | Default template | - |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` | - |

### Variable Validation Rules

#### sender_emails
```hcl
validation {
  condition = alltrue([
    for email in var.sender_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
  ])
  error_message = "All sender emails must be valid email addresses."
}
```

#### log_retention_days
```hcl
validation {
  condition = contains([
    1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
  ], var.log_retention_days)
  error_message = "Log retention days must be a valid CloudWatch retention period."
}
```

#### bounce_rate_threshold / complaint_rate_threshold
```hcl
validation {
  condition     = var.bounce_rate_threshold >= 0 && var.bounce_rate_threshold <= 100
  error_message = "Bounce rate threshold must be between 0 and 100."
}
```

## Outputs

| Name | Description |
|------|-------------|
| `domain_identity_arn` | ARN of the SES domain identity (if configured) |
| `domain_identity_verification_token` | Verification token for domain identity |
| `dkim_tokens` | DKIM tokens for DNS configuration |
| `email_identities` | Map of verified email identities |
| `configuration_set_name` | Name of the SES configuration set |
| `configuration_set_arn` | ARN of the SES configuration set |
| `sns_topic_arn` | ARN of SNS topic for notifications (if enabled) |
| `sns_topic_name` | Name of SNS topic for notifications (if enabled) |
| `lead_notification_template_name` | Name of lead notification template |
| `welcome_email_template_name` | Name of welcome email template (if enabled) |
| `ses_sending_role_arn` | ARN of SES sending IAM role (if created) |
| `ses_sending_role_name` | Name of SES sending IAM role (if created) |
| `cloudwatch_log_group_name` | Name of CloudWatch log group (if enabled) |
| `cloudwatch_log_group_arn` | ARN of CloudWatch log group (if enabled) |
| `mail_from_domain` | Custom MAIL FROM domain (if configured) |
| `sender_emails` | List of verified sender email addresses |
| `bounce_rate_alarm_name` | Name of bounce rate alarm (if monitoring enabled) |
| `complaint_rate_alarm_name` | Name of complaint rate alarm (if monitoring enabled) |

## Email Templates

### Lead Notification Template

Default template for notifying administrators of new leads:

**Subject**: `New Lead Captured: {{name}}`

**HTML Template**:
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>New Lead Notification</title>
</head>
<body>
    <h2>New Lead Captured</h2>
    <p><strong>Name:</strong> {{name}}</p>
    <p><strong>Email:</strong> {{email}}</p>
    <p><strong>Company:</strong> {{company}}</p>
    <p><strong>Source:</strong> {{source}}</p>
    <p><strong>Timestamp:</strong> {{timestamp}}</p>
    
    {{#if customFields}}
    <h3>Additional Information:</h3>
    <ul>
    {{#each customFields}}
        <li><strong>{{@key}}:</strong> {{this}}</li>
    {{/each}}
    </ul>
    {{/if}}
</body>
</html>
```

### Welcome Email Template (Optional)

Template for welcoming new leads:

**Subject**: `Welcome! Thank you for your interest`

**HTML Template**:
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Welcome</title>
</head>
<body>
    <h2>Thank you for your interest, {{name}}!</h2>
    <p>We've received your information and will be in touch soon.</p>
    <p>Best regards,<br>The Team</p>
</body>
</html>
```

### Template Variables

Available variables in templates:
- `{{name}}`: Lead's name
- `{{email}}`: Lead's email address
- `{{company}}`: Lead's company
- `{{source}}`: Source website/domain
- `{{timestamp}}`: Submission timestamp
- `{{customFields}}`: Additional form fields (object)

## Domain Verification

### DNS Records Required

#### Domain Verification
Add TXT record to your domain:
```
Name: _amazonses.example.com
Value: [verification_token from output]
```

#### DKIM Records (if enabled)
Add three CNAME records:
```
Name: [token1]._domainkey.example.com
Value: [token1].dkim.amazonses.com

Name: [token2]._domainkey.example.com
Value: [token2].dkim.amazonses.com

Name: [token3]._domainkey.example.com
Value: [token3].dkim.amazonses.com
```

#### MAIL FROM Domain (if configured)
Add MX record:
```
Name: mail.example.com
Value: 10 feedback-smtp.us-east-1.amazonses.com
```

Add TXT record:
```
Name: mail.example.com
Value: "v=spf1 include:amazonses.com ~all"
```

## Bounce and Complaint Handling

### SNS Topic Integration
- **Automatic Creation**: SNS topic for bounce/complaint notifications
- **Event Types**: Bounce, complaint, delivery, send, reject
- **Integration**: Can trigger Lambda functions or other AWS services

### Bounce Types
- **Hard Bounces**: Permanent delivery failures
- **Soft Bounces**: Temporary delivery failures
- **Complaints**: Spam reports from recipients

### Best Practices
1. **Monitor Bounce Rates**: Keep below 5%
2. **Monitor Complaint Rates**: Keep below 0.1%
3. **Remove Bad Addresses**: Automatically remove bounced emails
4. **Reputation Management**: Monitor sender reputation metrics

## CloudWatch Monitoring

### Metrics Tracked
- **Send**: Successful email sends
- **Bounce**: Email bounces
- **Complaint**: Spam complaints
- **Delivery**: Successful deliveries
- **Reject**: Rejected sends

### CloudWatch Alarms
- **Bounce Rate Alarm**: Triggers when bounce rate exceeds threshold
- **Complaint Rate Alarm**: Triggers when complaint rate exceeds threshold
- **Configurable Thresholds**: Customizable alert levels

### Log Events
- **Send Events**: Email sending attempts
- **Bounce Events**: Delivery failures
- **Complaint Events**: Spam reports
- **Delivery Events**: Successful deliveries

## IAM Permissions

### SES Sending Role (if created)
Permissions granted:
- `ses:SendEmail`: Send plain text emails
- `ses:SendRawEmail`: Send HTML emails
- `ses:SendTemplatedEmail`: Send template-based emails

### Conditions Applied
- **From Address Restriction**: Only allowed sender emails
- **Configuration Set**: Emails must use the configuration set

## Security Best Practices

### Email Authentication
- **DKIM**: Domain-based message authentication
- **SPF**: Sender Policy Framework records
- **DMARC**: Domain-based Message Authentication, Reporting & Conformance

### Access Control
- **IAM Roles**: Least-privilege access for sending
- **From Address Validation**: Restrict sending addresses
- **Configuration Sets**: Organized sending with tracking

### Data Protection
- **Encryption in Transit**: TLS encryption for email delivery
- **Template Security**: Validate template variables
- **Bounce Handling**: Secure processing of delivery failures

## Cost Optimization

### Pricing Factors
- **Email Volume**: $0.10 per 1,000 emails
- **Attachments**: Additional charges for large attachments
- **Dedicated IPs**: Optional dedicated IP addresses

### Cost Reduction Strategies
1. **Template Reuse**: Use templates instead of custom HTML
2. **Batch Sending**: Send multiple emails efficiently
3. **Bounce Management**: Remove invalid addresses quickly
4. **Monitoring**: Track usage to optimize sending patterns

## Integration Patterns

### Lambda Integration
```javascript
// Example Lambda function using SES
const AWS = require('aws-sdk');
const ses = new AWS.SES();

exports.handler = async (event) => {
  const params = {
    Source: 'noreply@example.com',
    Template: 'lead-notification',
    Destination: {
      ToAddresses: ['admin@example.com']
    },
    TemplateData: JSON.stringify({
      name: event.name,
      email: event.email,
      company: event.company,
      source: event.source,
      timestamp: new Date().toISOString()
    }),
    ConfigurationSetName: 'lead-capture-config-set'
  };
  
  return await ses.sendTemplatedEmail(params).promise();
};
```

### DynamoDB Streams Integration
- **Trigger**: DynamoDB stream events
- **Processing**: Send emails for new leads
- **Error Handling**: Dead letter queues for failed sends

## Troubleshooting

### Common Issues

1. **Domain Not Verified**: Complete DNS verification process
2. **DKIM Not Working**: Verify CNAME records are correct
3. **High Bounce Rate**: Clean email lists, verify addresses
4. **Emails in Spam**: Implement DKIM, SPF, and DMARC
5. **Sending Limits**: Request limit increases from AWS

### Verification Status
Check verification status:
```bash
aws ses get-identity-verification-attributes \
  --identities example.com user@example.com
```

### Testing Email Sending
```bash
aws ses send-email \
  --source noreply@example.com \
  --destination ToAddresses=test@example.com \
  --message Subject={Data="Test"},Body={Text={Data="Test message"}}
```

### Monitoring Commands
```bash
# Check sending statistics
aws ses get-send-statistics

# Check reputation
aws ses get-reputation \
  --identity example.com
```

## Dependencies

This module requires:
- **AWS Provider**: Version ~> 5.0
- **Terraform**: Version >= 1.0

## Integration with Other Modules

This module integrates with:
- **Lambda Module**: Provides email sending capabilities
- **DynamoDB Module**: Can trigger emails based on data changes
- **API Gateway Module**: Send confirmation emails for form submissions