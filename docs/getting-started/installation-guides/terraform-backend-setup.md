# Terraform Backend Infrastructure Setup Guide

This guide walks you through setting up the foundational infrastructure for Terraform state management in AWS. This setup is required before deploying the serverless lead capture system.

## Overview

### What are Terraform State Files?

Think of Terraform state files as Terraform's "memory" of your infrastructure. When you write Terraform code to create AWS resources (like Lambda functions, API Gateway, DynamoDB tables), Terraform needs to keep track of:

- **What resources exist**: "I created a Lambda function with ID `lambda-abc123`"
- **Current configuration**: "This Lambda has 512MB memory and runs Node.js 18"
- **Resource relationships**: "This API Gateway points to that Lambda function"
- **Resource metadata**: AWS-generated IDs, creation timestamps, etc.

**Example**: When you run `terraform apply` to create a Lambda function, Terraform:
1. Creates the Lambda in AWS
2. AWS returns the function's unique ID and ARN
3. Terraform saves this info in the state file
4. Next time you run `terraform plan`, Terraform compares your code to the state file to know what changed

### Why Remote State Storage?

**Without remote state (local file):**
- ❌ State file lives on your computer only
- ❌ Team members can't collaborate (they don't have your state file)
- ❌ If your computer crashes, you lose track of your infrastructure
- ❌ No protection against concurrent changes

**With remote state (S3 + DynamoDB):**
- ✅ State file stored in S3 (accessible to whole team)
- ✅ DynamoDB prevents two people from running Terraform simultaneously
- ✅ Versioning lets you recover from mistakes
- ✅ Encrypted and secure

### Team Collaboration Example

**Scenario**: You create a Lambda function, your teammate wants to add an API Gateway:

1. **You run**: `terraform apply` → Creates Lambda, saves state to S3
2. **Teammate runs**: `terraform plan` → Downloads state from S3, sees your Lambda exists
3. **Teammate adds**: API Gateway code that references your Lambda
4. **Teammate runs**: `terraform apply` → Creates API Gateway, updates shared state in S3
5. **You run**: `terraform plan` → Downloads updated state, sees both Lambda and API Gateway

Without shared state, your teammate would try to create resources that already exist or miss dependencies.

### Our Setup

We'll set up the backend infrastructure in **us-east-1** (where your CLI is configured), while the actual application will be deployed in **us-west-2** for better performance from Arizona.

**Backend Infrastructure (us-east-1):**
1. **S3 Bucket** - For storing Terraform state files with versioning and encryption
2. **DynamoDB Table** - For state locking to prevent concurrent modifications  
3. **IAM Policies** - For secure Terraform operations with least-privilege access

**Note**: This backend setup is separate from the application infrastructure that will be deployed in us-west-2.

## Prerequisites

- AWS CLI configured with appropriate credentials (see `aws-cli-setup.md`)
- AWS account with administrative access
- Basic understanding of AWS services

**Important**: If you're currently using your AWS root account, complete the "Personal Admin User Setup" section below before proceeding.

## Time Estimate

**Total Time**: 20-30 minutes (first time setup)

**Breakdown**:
- **S3 Bucket Setup**: 5-8 minutes
- **DynamoDB Table Setup**: 3-5 minutes  
- **IAM Policies & User**: 8-12 minutes
- **Terraform Backend Config**: 2-3 minutes
- **Testing & Verification**: 2-5 minutes

**Note**: Times assume familiarity with AWS Console. Add 10-15 minutes if this is your first time navigating AWS services.

## Personal Admin User Setup (Recommended)

If you're currently using your AWS root account, create a personal admin IAM user for development work. This follows AWS security best practices by limiting root account usage.

### Step 1: Create Development Admin Policy

1. Navigate to **IAM Console** → **Policies** → **Create policy**
2. Click **JSON** tab and use this policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ServerlessLeadCaptureServices",
            "Effect": "Allow",
            "Action": [
                "lambda:*",
                "apigateway:*",
                "dynamodb:*",
                "s3:*",
                "logs:*",
                "ses:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "MauticServerServices",
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "rds:*",
                "elasticache:*",
                "elasticfilesystem:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudfront:*",
                "route53:*",
                "acm:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "N8nServerlessServices",
            "Effect": "Allow",
            "Action": [
                "ecs:*",
                "ecr:*",
                "secretsmanager:*",
                "ssm:*",
                "application-autoscaling:*",
                "servicediscovery:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ServerlessWorkflowServices",
            "Effect": "Allow",
            "Action": [
                "events:*",
                "scheduler:*",
                "sqs:*",
                "sns:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "NetworkingAndSecurity",
            "Effect": "Allow",
            "Action": [
                "ec2:*Vpc*",
                "ec2:*Subnet*",
                "ec2:*InternetGateway*",
                "ec2:*RouteTable*",
                "ec2:*Route",
                "ec2:*NetworkAcl*",
                "ec2:*NatGateway*",
                "ec2:*VpnGateway*",
                "ec2:Describe*",
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:CreateKeyPair",
                "ec2:DeleteKeyPair",
                "ec2:ImportKeyPair"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMForResourceManagement",
            "Effect": "Allow",
            "Action": [
                "iam:ListRoles",
                "iam:ListPolicies",
                "iam:ListInstanceProfiles",
                "iam:GetRole",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:GetInstanceProfile",
                "iam:CreateRole",
                "iam:CreatePolicy",
                "iam:CreateInstanceProfile",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:AddRoleToInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:PassRole",
                "iam:TagRole",
                "iam:TagPolicy",
                "iam:UntagRole",
                "iam:UntagPolicy"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMSelfManagement",
            "Effect": "Allow",
            "Action": [
                "iam:ListMFADevices",
                "iam:ListVirtualMFADevices",
                "iam:CreateVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:ResyncMFADevice",
                "iam:ChangePassword",
                "iam:GetUser",
                "iam:ListAccessKeys",
                "iam:CreateAccessKey",
                "iam:UpdateAccessKey",
                "iam:DeleteAccessKey"
            ],
            "Resource": [
                "arn:aws:iam::*:user/${aws:username}",
                "arn:aws:iam::*:mfa/${aws:username}"
            ]
        },
        {
            "Sid": "MonitoringAndDebugging",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:*",
                "cloudtrail:LookupEvents",
                "xray:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "InfrastructureAsCode",
            "Effect": "Allow",
            "Action": [
                "cloudformation:*",
                "sts:GetCallerIdentity",
                "sts:AssumeRole"
            ],
            "Resource": "*"
        },
        {
            "Sid": "DenyBillingAccess",
            "Effect": "Deny",
            "Action": [
                "aws-portal:*",
                "budgets:*",
                "ce:*",
                "cur:*",
                "purchase-orders:*",
                "billing:*",
                "payments:*",
                "tax:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "DenyAccountManagement",
            "Effect": "Deny",
            "Action": [
                "organizations:*",
                "account:*",
                "aws-portal:*Billing*",
                "aws-portal:*Usage*",
                "aws-portal:*PaymentMethods*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "DenyHighRiskActions",
            "Effect": "Deny",
            "Action": [
                "iam:DeleteRole",
                "iam:DeleteUser",
                "iam:DeleteAccessKey",
                "iam:CreateUser",
                "iam:DeletePolicy"
            ],
            "Resource": [
                "arn:aws:iam::*:user/root",
                "arn:aws:iam::*:user/*-admin",
                "arn:aws:iam::*:role/OrganizationAccountAccessRole"
            ]
        }
    ]
}
```

3. **Policy name**: `MarketingStackDeveloperAccess`
4. **Description**: `AWS access for lead capture, Mautic, and n8n server deployments`
5. Click **Create policy**

### Step 2: Create Personal Admin User

1. Navigate to **Users** → **Create user**
2. **User name**: `[your-name]-dev-admin` (e.g., `john-dev-admin`)
3. **Access type**: 
   - ✅ Provide user access to the AWS Management Console
   - ✅ I want to create an IAM user (not Identity Center)
4. **Console password**: 
   - Choose **Custom password** and set a strong password
   - ✅ Users must create a new password at next sign-in
5. **Permissions**: 
   - Select **Attach policies directly**
   - Search and select `MarketingStackDeveloperAccess`
6. **Tags** (optional):
   - Key: `Purpose`, Value: `development-admin`
   - Key: `Owner`, Value: `[your-name]`
7. Click **Create user**

### Step 3: Set Up Programmatic Access

1. Select your newly created user
2. Go to **Security credentials** tab
3. Click **Create access key**
4. **Use case**: Command Line Interface (CLI)
5. **Description**: `Development CLI access`
6. Click **Create access key**
7. **Important**: Download the CSV or copy the credentials securely

### Step 4: Enable MFA (Highly Recommended)

1. In your user's **Security credentials** tab
2. Click **Assign MFA device**
3. **Device name**: `[your-name]-phone` or similar
4. **MFA device**: Authenticator app (recommended)
5. Follow the setup process with your phone's authenticator app
6. **Important**: Save backup codes securely

### Step 5: Configure AWS CLI

Update your AWS CLI to use the new IAM user:

```bash
# Configure new profile for your admin user
aws configure --profile dev-admin
# Enter your new access key ID
# Enter your new secret access key  
# Default region: us-east-1
# Default output format: json

# Set as default profile (optional)
export AWS_PROFILE=dev-admin

# Test the configuration
aws sts get-caller-identity
```

### Step 6: Secure Your Root Account

Now that you have an admin user:

1. **Remove root access keys** (if any exist)
2. **Enable MFA on root account**
3. **Store root credentials securely** (password manager)
4. **Use root only for**:
   - Billing and account settings
   - Closing the account
   - Changing support plans
   - Restoring IAM user permissions (emergency)

### What This Policy Allows vs Denies

**✅ Serverless Lead Capture:**
- Lambda functions, API Gateway, DynamoDB
- S3 buckets, CloudWatch logs, SES email

**✅ Mautic Server Deployment:**
- EC2 instances, RDS databases, ElastiCache
- Load balancers, Auto Scaling, CloudFront CDN
- Route 53 DNS, SSL certificates (ACM)
- EFS file systems for shared storage

**✅ Serverless n8n & Lambda Workflows:**
- ECS Fargate (serverless containers), ECR repositories
- Lambda functions for simple workflows
- EventBridge, SQS, SNS for triggers and messaging
- Secrets Manager, Systems Manager for configuration
- Auto-scaling to zero when idle

**✅ Infrastructure & Networking:**
- VPC, subnets, security groups, key pairs
- CloudFormation and Terraform operations
- IAM roles and policies (limited scope)
- CloudWatch monitoring and X-Ray tracing

**❌ Blocks Access To:**
- Billing and cost management
- Account-level settings and organization management
- Creating/deleting admin users or critical IAM resources
- High-risk account operations

### Verification

Test your new user has appropriate access:

```bash
# Should work - list S3 buckets
aws s3 ls

# Should work - describe EC2 instances
aws ec2 describe-instances

# Should fail - access billing
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```

**Important**: Once you've verified the admin user works, stop using your root account for daily development tasks.

## Step 1: Create S3 Bucket for Terraform State

### 1.1 Navigate to S3 Console

1. Log into the [AWS Management Console](https://console.aws.amazon.com/)
2. Navigate to **Services** → **Storage** → **S3**
3. Click **Create bucket**

### 1.2 Configure Bucket Settings

**Basic Configuration:**
- **Bucket name**: `terraform-state-[your-project-name]-[random-suffix]`
  - Example: `terraform-state-lead-capture-a1b2c3`
  - Must be globally unique across all AWS accounts
- **AWS Region**: `us-east-1` (recommended for Terraform state backend)
- **Object Ownership**: ACLs disabled (recommended)

**Block Public Access Settings:**
- ✅ Block all public access (keep all checkboxes checked)
- This ensures your Terraform state files are never publicly accessible

**Bucket Versioning:**
- ✅ Enable versioning
- This allows recovery from accidental state file corruption

**Default Encryption:**
- **Encryption type**: Server-side encryption with Amazon S3 managed keys (SSE-S3)
- **Bucket Key**: Enabled (reduces encryption costs)

**Advanced Settings:**
- **Object Lock**: Disabled (not needed for Terraform state)
- **Tags**: Add relevant tags for cost tracking
  - Key: `Project`, Value: `serverless-lead-capture`
  - Key: `Environment`, Value: `shared`
  - Key: `Purpose`, Value: `terraform-state`

### 1.3 Create the Bucket

1. Review all settings
2. Click **Create bucket**
3. **Important**: Note down the exact bucket name for later use

### 1.4 Configure Lifecycle Policy (Optional but Recommended)

1. Select your newly created bucket
2. Go to **Management** tab
3. Click **Create lifecycle rule**
4. **Rule name**: `terraform-state-cleanup`
5. **Rule scope**: Apply to all objects in the bucket
6. **Lifecycle rule actions**:
   - ✅ Delete incomplete multipart uploads after 7 days
   - ✅ Delete previous versions of objects after 90 days
7. Click **Create rule**

## Step 2: Create DynamoDB Table for State Locking

### 2.1 Navigate to DynamoDB Console

1. In AWS Console, navigate to **Services** → **Database** → **DynamoDB**
2. Click **Create table**

### 2.2 Configure Table Settings

**Table Details:**
- **Table name**: `terraform-state-lock`
- **Partition key**: `LockID` (String)
- **Sort key**: Leave empty (not needed)

**Table Settings:**
- **Table class**: DynamoDB Standard
- **Capacity mode**: On-demand (recommended for Terraform usage patterns)
  - Alternatively, use Provisioned with 5 RCU and 5 WCU for cost optimization

**Encryption Settings:**
- **Encryption at rest**: Owned by Amazon DynamoDB (default)
- **Point-in-time recovery**: Enabled (recommended for production)

**Tags:**
- Key: `Project`, Value: `serverless-lead-capture`
- Key: `Environment`, Value: `shared`
- Key: `Purpose`, Value: `terraform-locking`

### 2.3 Create the Table

1. Review all settings
2. Click **Create table**
3. Wait for table creation to complete (usually 1-2 minutes)
4. **Important**: Note down the table name and region

## Step 3: Create IAM Policy for Terraform Operations

### 3.1 Navigate to IAM Console

1. In AWS Console, navigate to **Services** → **Security, Identity, & Compliance** → **IAM**
2. Click **Policies** in the left sidebar
3. Click **Create policy**

### 3.2 Create Terraform Backend Policy

1. Click **JSON** tab
2. Replace the default policy with the following:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TerraformStateAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket",
                "s3:GetBucketVersioning",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::terraform-state-lead-capture-*",
                "arn:aws:s3:::terraform-state-lead-capture-*/*"
            ]
        },
        {
            "Sid": "TerraformStateLocking",
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:DescribeTable"
            ],
            "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock"
        }
    ]
}
```

3. **Policy name**: `TerraformBackendAccess`
4. **Description**: `Allows Terraform to access S3 state bucket and DynamoDB locking table`
5. Click **Create policy**

### 3.3 Create Terraform Operations Policy

Create a second policy for general Terraform operations:

1. Click **Create policy** again
2. Use the **JSON** tab with this policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TerraformGeneralAccess",
            "Effect": "Allow",
            "Action": [
                "apigateway:*",
                "lambda:*",
                "dynamodb:*",
                "iam:*",
                "logs:*",
                "ses:*",
                "route53:*",
                "acm:*",
                "cloudformation:*",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups"
            ],
            "Resource": "*"
        },
        {
            "Sid": "TerraformPassRole",
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": [
                        "lambda.amazonaws.com",
                        "apigateway.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
```

3. **Policy name**: `TerraformOperationsAccess`
4. **Description**: `Allows Terraform to manage AWS resources for the lead capture system`
5. Click **Create policy**

### 3.4 Create IAM User for Terraform (Recommended)

1. Navigate to **Users** in IAM console
2. Click **Create user**
3. **User name**: `terraform-lead-capture`
4. **Provide user access to AWS Management Console**: Leave **unchecked** (programmatic access only)
5. Click **Next**
6. **Permissions options**: Select **Attach policies directly**
7. **Permissions policies**: 
   - Search and select `TerraformBackendAccess`
   - Search and select `TerraformOperationsAccess`
8. Click **Next**
9. **Tags** (optional):
   - Key: `Project`, Value: `serverless-lead-capture`
   - Key: `Purpose`, Value: `terraform-automation`
10. Click **Create user**
11. **Create access keys**: After user creation, click on the user name
12. Go to **Security credentials** tab
13. Click **Create access key**
14. **Use case**: Select **Command Line Interface (CLI)**
15. **Description tag**: `Terraform CLI access`
16. Click **Create access key**
17. **Important**: Download the CSV file or copy the access key and secret key securely

## Step 4: Configure Terraform Backend

### 4.1 Create Terraform Configuration Directory

First, create a directory for your Terraform configuration:

```bash
# Navigate to your project directory
cd mautic

# Create Terraform configuration directory
mkdir -p terraform/environments/dev
cd terraform/environments/dev
```

### 4.2 Create Backend Configuration Files (Recommended Approach)

**Why separate configuration?** This approach keeps your Terraform code public-safe while allowing different configurations for dev/staging/prod environments.

#### Create backend.tf (Public - Safe for Git)

Create `backend.tf` in the `terraform/environments/dev` directory:

```hcl
terraform {
  backend "s3" {
    # Configuration provided via backend.hcl file
    # Run: terraform init -backend-config=backend.hcl
  }
}

# Provider configuration for application deployment
provider "aws" {
  region = "us-west-2"  # Application resources will be deployed here
}
```

#### Create backend.hcl (Private - Not Committed)

Create `backend.hcl` in the same directory:

```hcl
bucket         = "terraform-state-lead-capture-a1b2c3"  # Replace with your actual bucket name
key            = "lead-capture/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-state-lock"
encrypt        = true

# Optional: Use specific AWS profile
# profile = "terraform-user"
```

#### Create .gitignore (Security)

Create or update `.gitignore` in your project root (`mautic/.gitignore`):

```gitignore
# Terraform backend configuration files (contain sensitive info)
*.hcl
backend.hcl

# Terraform state files
*.tfstate
*.tfstate.*

# Terraform variable files that may contain sensitive data
*.tfvars
*.tfvars.json

# AWS credentials and config
.aws/
aws-credentials.csv

# Terraform directories
.terraform/
.terraform.lock.hcl
```

#### Benefits of This Approach

✅ **Security**: Actual resource names stay private
✅ **Multi-environment**: Easy to have dev.hcl, staging.hcl, prod.hcl
✅ **Code Review**: Reviewers can see structure without sensitive details
✅ **Best Practice**: Follows Terraform security recommendations
✅ **Flexibility**: Same code works across different AWS accounts/regions

### 4.3 Initialize Terraform Backend

Run the following commands in your `terraform/environments/dev` directory:

```bash
# Initialize Terraform with the private configuration
terraform init -backend-config=backend.hcl

# Verify backend configuration
terraform plan
```

**Important**: Always use `-backend-config=backend.hcl` when initializing. This tells Terraform to load the private configuration from the .hcl file.

If successful, you should see output indicating that Terraform is using the S3 backend with your specific bucket name.

### 4.4 Multi-Environment Setup (Optional)

For future staging/production environments, create additional .hcl files:

```bash
# Different configurations for different environments
terraform/environments/
├── dev/
│   ├── backend.tf          # Same code
│   └── backend.hcl         # Dev-specific config
├── staging/
│   ├── backend.tf          # Same code  
│   └── backend.hcl         # Staging-specific config
└── prod/
    ├── backend.tf          # Same code
    └── backend.hcl         # Production-specific config
```

This allows you to use the same Terraform code across environments while keeping configurations separate and secure.

## Step 5: Verification and Testing

### 5.1 Verify S3 Bucket Setup

1. Navigate to your S3 bucket in the AWS Console
2. After running `terraform init`, you should see a state file at the specified key path
3. Check that versioning is enabled and working

### 5.2 Verify DynamoDB Table

1. Navigate to your DynamoDB table in the AWS Console
2. During `terraform plan` or `terraform apply`, you should see lock entries appear temporarily
3. The table should be empty when no Terraform operations are running

### 5.3 Test State Locking

Run this test to ensure state locking works:

```bash
# In terminal 1
terraform plan

# In terminal 2 (while terminal 1 is still running)
terraform plan
```

Terminal 2 should show a message about waiting for the state lock to be released.

## Security Best Practices

### 5.1 Bucket Security Checklist

- ✅ Public access blocked
- ✅ Versioning enabled
- ✅ Encryption enabled
- ✅ Lifecycle policies configured
- ✅ Access logging enabled (optional)

### 5.2 IAM Security Checklist

- ✅ Least-privilege policies
- ✅ Dedicated Terraform user
- ✅ Regular access key rotation
- ✅ MFA enabled for console access (if applicable)

### 5.3 DynamoDB Security Checklist

- ✅ Encryption at rest enabled
- ✅ Point-in-time recovery enabled
- ✅ Appropriate IAM permissions

## Troubleshooting

### Common Issues

**Error: "bucket does not exist"**
- Verify bucket name spelling
- Ensure you're in the correct AWS region
- Check AWS credentials and permissions

**Error: "table does not exist"**
- Verify DynamoDB table name and region
- Ensure table creation completed successfully
- Check IAM permissions for DynamoDB access

**Error: "Access Denied"**
- Verify IAM policies are attached correctly
- Check AWS credentials configuration
- Ensure bucket and table are in the expected region

**State Lock Timeout**
- Check if another Terraform process is running
- Manually remove lock from DynamoDB if process crashed
- Verify DynamoDB table permissions

### Manual Lock Removal (Emergency Only)

If Terraform crashes and leaves a lock, you can manually remove it:

1. Go to DynamoDB console
2. Open the `terraform-state-lock` table
3. Find the item with your state file path
4. Delete the item
5. **Warning**: Only do this if you're certain no other Terraform process is running

## Cost Considerations

### S3 Costs
- Storage: ~$0.023 per GB per month (Standard tier)
- Requests: Minimal for Terraform usage
- Versioning: Additional storage for old versions

### DynamoDB Costs
- On-demand: ~$1.25 per million read/write requests
- Provisioned: ~$0.25 per RCU/WCU per month
- For Terraform usage, on-demand is typically more cost-effective

### Estimated Monthly Cost
- S3: <$1 for typical Terraform state files
- DynamoDB: <$1 for typical Terraform usage
- **Total**: <$5/month for backend infrastructure

## Next Steps

After completing this setup:

1. ✅ S3 bucket created and configured
2. ✅ DynamoDB table created and configured  
3. ✅ IAM policies and user created
4. ✅ Terraform backend configured and tested

You can now proceed to:
- Configure your development environment
- Set up the private repository for production deployments
- Begin deploying the serverless lead capture infrastructure

## Reference Information

### AWS Resource Names (Update with your values)

```bash
# S3 Bucket
TERRAFORM_STATE_BUCKET="terraform-state-lead-capture-a1b2c3"

# DynamoDB Table
TERRAFORM_LOCK_TABLE="terraform-state-lock"

# IAM User
TERRAFORM_USER="terraform-lead-capture"

# Regions
TERRAFORM_BACKEND_REGION="us-east-1"  # For state storage
APPLICATION_REGION="us-west-2"        # For application deployment
```

### Useful AWS CLI Commands

```bash
# Verify S3 bucket exists
aws s3 ls s3://terraform-state-lead-capture-a1b2c3

# Check DynamoDB table status
aws dynamodb describe-table --table-name terraform-state-lock

# List IAM policies for user
aws iam list-attached-user-policies --user-name terraform-lead-capture
```

---

**Important**: Keep this guide updated with your actual resource names and regions. Store sensitive information like access keys securely and never commit them to version control.