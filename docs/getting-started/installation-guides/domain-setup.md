# Domain and Route 53 Setup Guide

This guide walks you through setting up a custom domain for your serverless lead capture API endpoints using AWS Route 53 and Certificate Manager. **This is an optional future enhancement** - you can start development using AWS-generated API Gateway URLs and add custom domains when ready for production.

## Overview

### Development vs Production URLs

**Development (Start Here):**
- API Gateway URL: `https://abc123def.execute-api.us-west-2.amazonaws.com/prod/leads`
- Use this for initial development and testing
- No domain setup required

**Production (Future Enhancement):**
- Custom API URL: `https://api.yourdomain.com/leads`
- Professional appearance for embedded forms
- Better CORS handling and branding

### What is Route 53?

**Route 53** is Amazon's DNS (Domain Name System) service. Think of DNS as the internet's phone book - it translates human-readable domain names (like `yourdomain.com`) into IP addresses that computers use to find servers.

**Route 53 Features:**
- **Domain Registration**: Buy and manage domain names
- **DNS Hosting**: Manage DNS records for your domains
- **Health Checks**: Monitor your services and route traffic accordingly
- **AWS Integration**: Seamlessly connects with other AWS services

### Understanding CORS (Cross-Origin Resource Sharing)

**What is CORS?**
CORS is a security feature built into web browsers that controls which websites can make requests to your API.

**The Problem:**
```
Your Website:    https://yourdomain.com
Your API:        https://abc123.execute-api.us-west-2.amazonaws.com

Browser says: "These are different origins - request blocked!"
```

**Different Origins Include:**
- Different domains: `yourdomain.com` vs `anotherdomain.com`
- Different subdomains: `yourdomain.com` vs `api.yourdomain.com`
- Different protocols: `http://` vs `https://`
- Different ports: `:80` vs `:443`

**Why CORS Matters for Lead Capture:**
When someone visits your website at `yourdomain.com` and fills out your lead form, their browser will try to send that data to your API. If the API is on a different origin, the browser blocks the request for security reasons.

**CORS Solutions:**

**Option 1: Configure API to Allow Your Domain**
```javascript
// API Gateway CORS headers
Access-Control-Allow-Origin: https://yourdomain.com
Access-Control-Allow-Methods: POST, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

**Option 2: Use Same Parent Domain (Recommended)**
```
Your Website: https://yourdomain.com
Your API:     https://api.yourdomain.com  ← Same parent domain
```

This is why we recommend the subdomain approach - it makes CORS configuration much simpler and more secure.

### Services Used

1. **Route 53** - Amazon's DNS service for domain management
2. **Certificate Manager (ACM)** - Free SSL/TLS certificates for AWS services
3. **API Gateway** - Custom domain mapping for professional URLs

## When to Use This Guide

**Skip for Now If:**
- You're just starting development
- You want to test the lead capture system first
- You're comfortable using AWS-generated URLs initially

**Use This Guide When:**
- You're ready to deploy to production
- You want professional-looking API URLs
- You need better CORS handling for your frontend domain

## Prerequisites

- AWS CLI configured with your development user
- Your existing frontend domain (where the lead capture form will be embedded)
- Basic understanding of DNS concepts
- Completed serverless infrastructure deployment

## Time Estimate

**Total Time**: 30-60 minutes (plus DNS propagation time)

**Breakdown**:
- **Domain Registration/Transfer**: 10-15 minutes (if needed)
- **Hosted Zone Setup**: 5-10 minutes
- **SSL Certificate Setup**: 10-15 minutes
- **DNS Configuration**: 5-10 minutes
- **DNS Propagation**: 5 minutes - 48 hours (varies)

## Option 1: Register New Domain with Route 53 (Recommended)

### Step 1: Register Domain

1. **Navigate to Route 53 Console**
   - Go to **Services** → **Route 53**
   - Click **Registered domains** in left sidebar

2. **Register New Domain**
   - Click **Register domain**
   - **Search for domain**: Enter your desired domain name
   - **Choose TLD**: `.com`, `.org`, `.net`, etc.
   - **Check availability** and select domain

3. **Domain Configuration**
   - **Duration**: 1 year (minimum)
   - **Auto-renew**: Enabled (recommended)
   - **Privacy protection**: Enabled (recommended)

4. **Contact Information**
   - Fill in registrant contact details
   - **Important**: Use accurate information for domain ownership

5. **Complete Registration**
   - Review details and pricing
   - Click **Complete purchase**
   - **Cost**: Typically $12-15/year for .com domains

### Step 2: Verify Hosted Zone Creation

1. **Check Hosted Zones**
   - Go to **Route 53** → **Hosted zones**
   - You should see your domain listed automatically
   - **Note**: Route 53 creates this automatically for registered domains

2. **Record Name Servers**
   - Click on your domain's hosted zone
   - Note the 4 **NS (Name Server)** records
   - These should already be configured for Route 53 registered domains

## Option 2: Transfer Existing Domain to Route 53

### Step 1: Prepare Domain Transfer

1. **Unlock Domain** (at current registrar)
   - Log into your current domain registrar
   - Unlock the domain for transfer
   - Disable privacy protection temporarily

2. **Get Authorization Code**
   - Request EPP/authorization code from current registrar
   - **Important**: Keep this code secure

### Step 2: Initiate Transfer

1. **Route 53 Console**
   - Go to **Route 53** → **Registered domains**
   - Click **Transfer domain**

2. **Transfer Configuration**
   - **Domain name**: Enter your domain
   - **Authorization code**: Enter EPP code from current registrar
   - **Duration**: Choose transfer duration

3. **Complete Transfer**
   - Follow verification steps (email confirmation)
   - **Timeline**: Transfers typically take 5-7 days

## Option 3: Keep Domain Elsewhere, Use Route 53 for DNS Only

### Step 1: Create Hosted Zone

1. **Route 53 Console**
   - Go to **Route 53** → **Hosted zones**
   - Click **Create hosted zone**

2. **Hosted Zone Configuration**
   - **Domain name**: Enter your domain (e.g., `yourdomain.com`)
   - **Type**: Public hosted zone
   - **Comment**: Optional description
   - Click **Create hosted zone**

### Step 2: Update Name Servers

1. **Get Route 53 Name Servers**
   - Click on your newly created hosted zone
   - Note the 4 **NS records** (e.g., `ns-123.awsdns-12.com`)

2. **Update at Current Registrar**
   - Log into your domain registrar
   - Find DNS/Name Server settings
   - Replace existing name servers with Route 53 name servers
   - **Important**: Use all 4 name servers provided

3. **Verify DNS Propagation**
   ```bash
   # Check name servers (may take 24-48 hours)
   dig NS yourdomain.com
   
   # Should show Route 53 name servers
   ```

## SSL Certificate Setup

### Step 1: Request Certificate in ACM

1. **Certificate Manager Console**
   - Go to **Services** → **Certificate Manager**
   - **Important**: Must be in **us-east-1** region for API Gateway
   - Click **Request a certificate**

2. **Certificate Configuration**
   - **Certificate type**: Request a public certificate
   - **Domain names**: 
     - `api.yourdomain.com` (for API endpoints)
     - `*.yourdomain.com` (wildcard, optional)
   - **Validation method**: DNS validation (recommended)

3. **DNS Validation**
   - Click **Request**
   - **Add CNAME records**: ACM will provide CNAME records
   - **Route 53 Integration**: Click **Create record in Route 53** (if using Route 53)
   - **Manual DNS**: Add CNAME records to your DNS provider

### Step 2: Verify Certificate

1. **Wait for Validation**
   - Certificate status should change to **Issued**
   - **Timeline**: 5-30 minutes with Route 53, up to 72 hours with other DNS providers

2. **Troubleshooting Validation**
   ```bash
   # Check DNS validation record
   dig CNAME _abc123.yourdomain.com
   
   # Should return ACM validation CNAME
   ```

## DNS Configuration for API Subdomain

### Step 1: Create API Subdomain Record

1. **Route 53 Hosted Zone**
   - Go to your domain's hosted zone
   - Click **Create record**

2. **Record Configuration**
   - **Record name**: `api` (creates `api.yourdomain.com`)
   - **Record type**: A - Routes traffic to an IPv4 address
   - **Alias**: Yes
   - **Route traffic to**: 
     - **Alias to API Gateway API**
     - **Region**: us-west-2 (your application region)
     - **API Gateway**: Select your API (created later in deployment)

**Recommended Subdomain Approach:**
Since you have an existing frontend domain, we recommend using a subdomain for your API:

```
Your Frontend:  https://yourdomain.com (existing)
Your API:       https://api.yourdomain.com (new subdomain)
```

**Why This Works Best:**
- **CORS Friendly**: Same parent domain simplifies cross-origin requests
- **Professional**: Industry standard pattern (`api.company.com`)
- **Scalable**: Easy to add more services (`auth.yourdomain.com`, `webhooks.yourdomain.com`)
- **SSL Efficient**: Can use wildcard certificates (`*.yourdomain.com`)

**Alternative Subdomain Names:**
- `api.yourdomain.com` - Standard API subdomain (recommended)
- `leads.yourdomain.com` - Specific to lead capture
- `forms.yourdomain.com` - If you plan multiple form types
- `backend.yourdomain.com` - Generic backend services

**Note**: You'll complete this step after deploying your API Gateway in later tasks.

## Verification and Testing

### Step 1: DNS Propagation Check

```bash
# Check domain resolution
nslookup yourdomain.com

# Check API subdomain (after API Gateway setup)
nslookup api.yourdomain.com

# Check SSL certificate
openssl s_client -connect api.yourdomain.com:443 -servername api.yourdomain.com
```

### Step 2: Online DNS Tools

Use online tools to verify DNS propagation:
- **whatsmydns.net**: Check global DNS propagation
- **dnschecker.org**: Verify DNS records worldwide
- **ssllabs.com/ssltest**: Test SSL certificate configuration

## Cost Considerations

### Route 53 Costs

**Hosted Zone**: $0.50 per hosted zone per month
**DNS Queries**: $0.40 per million queries (first 1 billion queries/month)
**Domain Registration**: $12-15/year for .com domains

### Certificate Manager Costs

**Public SSL Certificates**: **FREE** for AWS services
**Private Certificates**: $400/month (not needed for this project)

### Estimated Monthly Cost

- **Hosted Zone**: $0.50/month
- **DNS Queries**: <$1/month for typical usage
- **SSL Certificate**: $0 (free)
- **Total**: ~$1-2/month + annual domain registration

## Security Best Practices

### Domain Security

- ✅ Enable domain privacy protection
- ✅ Use strong registrar account passwords
- ✅ Enable two-factor authentication at registrar
- ✅ Set up domain lock/transfer protection

### DNS Security

- ✅ Use DNSSEC (available in Route 53)
- ✅ Monitor DNS changes with CloudTrail
- ✅ Restrict Route 53 access via IAM policies
- ✅ Regular DNS record audits

### SSL Certificate Security

- ✅ Use DNS validation (more secure than email)
- ✅ Monitor certificate expiration (ACM auto-renews)
- ✅ Use strong cipher suites (ACM handles this)
- ✅ Enable HSTS headers in API Gateway

## Troubleshooting

### Common Issues

**Domain not resolving**
- Check name server configuration at registrar
- Verify DNS propagation (can take 24-48 hours)
- Ensure hosted zone is configured correctly

**SSL certificate validation failing**
- Verify CNAME records are added correctly
- Check DNS propagation for validation records
- Ensure certificate is requested in us-east-1 region

**API subdomain not working**
- Verify API Gateway custom domain is configured
- Check Route 53 alias record points to correct API Gateway
- Ensure SSL certificate covers the subdomain

### DNS Propagation Timeline

- **Local DNS**: 5-15 minutes
- **ISP DNS**: 1-4 hours  
- **Global DNS**: 24-48 hours
- **Complete propagation**: Up to 72 hours

## Development vs Production Workflow

### Phase 1: Development (Start Here)
1. **Skip this domain setup** for now
2. **Deploy serverless infrastructure** with Terraform
3. **Use AWS-generated API URLs** for development:
   ```
   https://abc123def.execute-api.us-west-2.amazonaws.com/prod/leads
   ```
4. **Configure CORS** to allow your frontend domain
5. **Test lead capture form** on your existing website

### Phase 2: Production (When Ready)
1. **Complete this domain setup guide**
2. **Configure custom domain** in API Gateway
3. **Update form configuration** to use custom API URL:
   ```
   https://api.yourdomain.com/leads
   ```
4. **Test and deploy** production version

## Next Steps

**For Development (Recommended Next):**
- Skip to deploying your serverless infrastructure
- Use AWS-generated URLs for initial testing
- Return to this guide when ready for production

**For Production Setup:**
After completing domain setup:
1. ✅ Domain DNS managed by Route 53
2. ✅ SSL certificate issued and validated  
3. ✅ API subdomain configured
4. ✅ Custom domain mapped to API Gateway

You can then:
- Configure API Gateway with custom domain
- Update your lead capture form to use professional URLs
- Deploy the production version of your system

## Reference Information

### DNS Record Types Used

```bash
# Example DNS records for yourdomain.com
yourdomain.com.        IN  A      # Points to hosting (if needed)
api.yourdomain.com.    IN  A      # Alias to API Gateway
www.yourdomain.com.    IN  CNAME  # Points to main domain (optional)
```

### Useful Commands

```bash
# Check domain registration status
aws route53domains get-domain-detail --domain-name yourdomain.com

# List hosted zones
aws route53 list-hosted-zones

# Check certificate status
aws acm list-certificates --region us-east-1

# Test DNS resolution
dig yourdomain.com
nslookup api.yourdomain.com
```

---

**Important**: Keep your domain registrar credentials secure and enable all available security features. Domain hijacking can be devastating for online services.