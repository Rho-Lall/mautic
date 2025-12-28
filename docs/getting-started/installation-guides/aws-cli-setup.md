# AWS CLI Setup Guide

This guide will walk you through setting up AWS CLI v2 on macOS and configuring it for your personal AWS account.

## Prerequisites

- macOS system
- Terminal access
- Email address (for AWS account creation)

## Step 1: Create AWS Account

**Important**: AWS accounts are separate from Amazon retail accounts. You need a dedicated AWS account for cloud services.

1. **Go to AWS Sign-up**
   - Visit [aws.amazon.com](https://aws.amazon.com/)
   - Click "Create an AWS Account" (not "Sign In")

2. **Account Information**
   - Enter your email address
   - Choose a password
   - Enter an AWS account name (e.g., "YourName Personal AWS")
   - Click "Continue"

3. **Contact Information**
   - Select "Personal" account type
   - Enter your personal information
   - Enter your phone number
   - Click "Continue"

4. **Payment Information**
   - Enter a valid credit/debit card
   - **Note**: AWS has a generous free tier, but requires payment method for verification
   - Click "Continue"

5. **Identity Verification**
   - AWS will call or text you with a verification code
   - Enter the code when prompted
   - Click "Continue"

6. **Support Plan**
   - Select "Basic support - Free"
   - Click "Complete sign up"

7. **Account Activation**
   - Wait for account activation (usually takes a few minutes)
   - You'll receive a confirmation email

## Step 2: Install AWS CLI v2

### Option A: Using Homebrew (Recommended)

1. Open Terminal
2. Install Homebrew if you don't have it:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. Install AWS CLI v2:
   ```bash
   brew install awscli
   ```

4. Verify installation:
   ```bash
   aws --version
   ```
   You should see output like: `aws-cli/2.x.x Python/3.x.x Darwin/xx.x.x source/x86_64`

### Option B: Using Official Installer

1. Download the AWS CLI installer:
   ```bash
   curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
   ```

2. Run the installer:
   ```bash
   sudo installer -pkg AWSCLIV2.pkg -target /
   ```

3. Verify installation:
   ```bash
   aws --version
   ```

## Step 3: Create IAM User for Development

1. **Log into AWS Console**
   - Go to [AWS Console](https://console.aws.amazon.com/)
   - Sign in with your personal AWS account

2. **Navigate to IAM**
   - In the AWS Console, search for "IAM" in the services search bar
   - Click on "IAM" to open the Identity and Access Management console

3. **Create New User**
   - Click "Users" in the left sidebar
   - Click "Create user" button
   - Enter username: `serverless-lead-capture-dev`
   - Click "Next"

4. **Set Permissions**
   - Select "Attach policies directly"
   - For development, attach these policies (search and check each):
     - `AmazonAPIGatewayAdministrator`
     - `AWSLambda_FullAccess`
     - `AmazonDynamoDBFullAccess`
     - `AmazonS3FullAccess`
     - `AmazonSESFullAccess`
     - `CloudWatchFullAccess`
   - **For IAM permissions**, we'll create a custom policy (see next step)
   - Click "Next"

5. **Create Custom IAM Policy for Terraform**
   - Before completing user creation, we need to create a limited IAM policy
   - Open a new tab and go to IAM → Policies
   - Click "Create policy"
   - Click "JSON" tab and paste this policy:

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "iam:CreateRole",
                   "iam:DeleteRole",
                   "iam:GetRole",
                   "iam:ListRoles",
                   "iam:UpdateRole",
                   "iam:AttachRolePolicy",
                   "iam:DetachRolePolicy",
                   "iam:ListAttachedRolePolicies",
                   "iam:CreatePolicy",
                   "iam:DeletePolicy",
                   "iam:GetPolicy",
                   "iam:ListPolicies",
                   "iam:CreatePolicyVersion",
                   "iam:DeletePolicyVersion",
                   "iam:PassRole"
               ],
               "Resource": [
                   "arn:aws:iam::*:role/serverless-lead-capture-*",
                   "arn:aws:iam::*:policy/serverless-lead-capture-*"
               ]
           }
       ]
   }
   ```

   - Click "Next"
   - Name the policy: `ServerlessLeadCaptureIAMPolicy`
   - Description: "Limited IAM permissions for serverless lead capture project"
   - Click "Create policy"

6. **Attach Custom Policy to User**
   - Go back to your user creation tab
   - Click "Attach policies directly" if not already selected
   - Search for `ServerlessLeadCaptureIAMPolicy`
   - Check the box next to your custom policy
   - Click "Next"

7. **Review and Create**
   - Review the user details and attached policies
   - Click "Create user"

8. **Create Access Keys**
   - Click on the newly created user
   - Go to "Security credentials" tab
   - Click "Create access key"
   - Select "Command Line Interface (CLI)"
   - Check the confirmation checkbox
   - Click "Next"
   - Add description: "Development CLI access"
   - Click "Create access key"
   - **IMPORTANT**: Copy both the Access Key ID and Secret Access Key
   - Click "Done"

## Step 4: Configure AWS CLI

1. **Run AWS Configure**
   ```bash
   aws configure
   ```

2. **Enter Your Credentials**
   When prompted, enter:
   - **AWS Access Key ID**: [Your Access Key ID from Step 2]
   - **AWS Secret Access Key**: [Your Secret Access Key from Step 2]
   - **Default region name**: `us-east-1` (or your preferred region)
   - **Default output format**: `json`

3. **Verify Configuration**
   ```bash
   aws sts get-caller-identity
   ```
   
   You should see output like:
   ```json
   {
       "UserId": "AIDACKCEVSQ6C2EXAMPLE",
       "Account": "123456789012",
       "Arn": "arn:aws:iam::123456789012:user/serverless-lead-capture-dev"
   }
   ```

## Step 5: Test AWS CLI Access

1. **List S3 Buckets** (should work even if empty):
   ```bash
   aws s3 ls
   ```

2. **List Lambda Functions** (should return empty list):
   ```bash
   aws lambda list-functions
   ```

## Configuration Files Location

Your AWS credentials are stored in:
- **Credentials**: `~/.aws/credentials`
- **Config**: `~/.aws/config`

You can view these files:
```bash
cat ~/.aws/credentials
cat ~/.aws/config
```

## Adding IAM Policy to Existing User

If you already created the user without the custom IAM policy, here's how to add it:

1. **Create the Custom Policy** (if you haven't already):
   - Go to IAM → Policies in AWS Console
   - Click "Create policy"
   - Click "JSON" tab and paste the policy from step 5 above
   - Name it: `ServerlessLeadCaptureIAMPolicy`
   - Click "Create policy"

2. **Attach Policy to Existing User**:
   - Go to IAM → Users
   - Click on your `serverless-lead-capture-dev` user
   - Click "Permissions" tab
   - Click "Add permissions" → "Attach policies directly"
   - Search for `ServerlessLeadCaptureIAMPolicy`
   - Check the box next to it
   - Click "Add permissions"

3. **Remove IAMFullAccess** (if you added it):
   - In the same Permissions tab
   - Find `IAMFullAccess` in the list
   - Click the "X" next to it to remove it
   - Confirm the removal

## Security Best Practices

1. **Never commit AWS credentials to version control**
2. **Use IAM roles in production** instead of access keys
3. **Regularly rotate access keys** (every 90 days recommended)
4. **Use least-privilege permissions** in production

## Troubleshooting

### Common Issues

**"aws: command not found"**
- Restart your terminal
- Check if AWS CLI is in your PATH: `which aws`
- Try reinstalling with the other method

**"Unable to locate credentials"**
- Run `aws configure` again
- Check that credentials files exist: `ls -la ~/.aws/`
- Verify credentials format in `~/.aws/credentials`

**"Access Denied" errors**
- Verify your IAM user has the necessary permissions
- Check that you're using the correct region
- Ensure your access keys are active in the AWS Console

### Getting Help

- AWS CLI documentation: https://docs.aws.amazon.com/cli/
- AWS CLI command reference: https://docs.aws.amazon.com/cli/latest/reference/

## Next Steps

Once AWS CLI is configured successfully, you can proceed to:
- Task 0.2: Set up Terraform backend infrastructure
- Begin developing the serverless lead capture system

---

**Note**: Keep your access keys secure and never share them. If you suspect they've been compromised, immediately deactivate them in the AWS Console and create new ones.