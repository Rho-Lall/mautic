# Serverless Lead Capture System

A serverless lead capture form system that can be embedded into GitHub Pages websites and deployed on AWS infrastructure. This MVP serves as the foundation for future integration with Mautic marketing automation.

## 🚀 Quick Start

### Embed the Lead Capture Form

Add this snippet to any HTML page:

```html
<!-- Lead Capture Form -->
<div id="lead-capture-form" 
     data-api-endpoint="https://your-api-id.execute-api.us-west-2.amazonaws.com/prod/leads"
     data-fields="name,email,company">
</div>
<script src="https://your-cdn.com/lead-capture.js"></script>
```

### Example Integration

```html
<!DOCTYPE html>
<html>
<head>
    <title>My GitHub Pages Site</title>
</head>
<body>
    <h1>Welcome to My Site</h1>
    
    <!-- Your existing content -->
    <p>Learn more about our services...</p>
    
    <!-- Lead Capture Form -->
    <div id="lead-capture-form" 
         data-api-endpoint="https://abc123def.execute-api.us-west-2.amazonaws.com/prod/leads"
         data-fields="name,email,company"
         data-title="Get in Touch"
         data-submit-text="Send Message">
    </div>
    <script src="dist/lead-capture.js"></script>
</body>
</html>
```

## 🏗️ Architecture

### Runtime Flow
```
GitHub Pages → Lead Form (B) → API Gateway → Lambda (D) → DynamoDB
```

### Repository Structure
```
Public Repo (this repo):     Private Repo (production):
├── Form Code (F)            ├── Production Config (I)
├── Lambda Code (G)          ├── Secrets & State (J)  
└── Terraform Modules (H)    └── Deploy Workflows (K)
```

## 📁 Project Structure

```
├── src/
│   ├── client/                 # Frontend form components
│   │   ├── lead-capture.js     # Main form JavaScript
│   │   ├── lead-capture.css    # Form styling
│   │   └── embed-example.html  # Integration example
│   └── lambda/                 # Backend Lambda functions
│       ├── handlers/           # Lambda function handlers
│       │   ├── submit-lead.js  # Form submission handler
│       │   └── get-leads.js    # Lead retrieval API
│       ├── utils/              # Shared utilities
│       │   ├── validation.js   # Input validation
│       │   └── database.js     # DynamoDB operations
│       └── tests/              # Unit tests
├── terraform/
│   ├── modules/                # Reusable Terraform modules
│   │   ├── api-gateway/        # API Gateway module
│   │   ├── lambda/             # Lambda deployment module
│   │   ├── dynamodb/           # Database module
│   │   └── ses/                # Email service module
│   └── environments/
│       └── dev/                # Development environment
│           ├── backend.tf      # Terraform backend config
│           └── backend.hcl     # Private backend settings
├── docs/
│   └── installation-guides/   # Setup documentation
└── dist/                       # Built assets (generated)
```

## 🚀 Quick Integration (For Website Owners)

### Step 1: Get the Form Files

Download these files from the `src/client/` directory:
- `lead-capture.js` - The form JavaScript
- `lead-capture.css` - The form styling

### Step 2: Add to Your Website

**Copy the files to your website:**
```
your-website/
├── assets/
│   ├── lead-capture.js     ← Copy here
│   └── lead-capture.css    ← Copy here
└── index.html              ← Your page
```

**Add this HTML where you want the form:**
```html
<!-- In your <head> section -->
<link rel="stylesheet" href="assets/lead-capture.css">

<!-- Where you want the form to appear -->
<div id="lead-capture-form" 
     data-api-endpoint="https://your-api-endpoint.com/leads"
     data-fields="name,email,details"
     data-title="Contact Us">
</div>

<!-- Before closing </body> tag -->
<script src="assets/lead-capture.js"></script>
```

### Step 3: Configure Your API

Replace `https://your-api-endpoint.com/leads` with your actual API endpoint URL.

**📖 Need detailed integration help?** See the [Integration Guide](../../docs/integration.md) for platform-specific instructions (GitHub Pages, Jekyll, Gatsby, Next.js, etc.).

## 🛠️ Development Setup (For Developers)

### Prerequisites

- Node.js 18+ 
- AWS CLI configured
- Terraform installed
- AWS account with appropriate permissions

### Installation

```bash
# Navigate to this directory
cd serverless/lead-capture

# Install dependencies
npm install

# Build the project
npm run build

# Run local development server
npm run dev
```

### Testing

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Lint code
npm run lint
```

## 🚀 Deployment

### Development Environment

```bash
# Plan deployment
npm run deploy:plan

# Deploy to AWS
npm run deploy:dev
```

### Production Environment

Production deployment is handled through a separate private repository with encrypted secrets and automated workflows.

## 🔧 Configuration Options

### Form Configuration

The lead capture form supports various configuration options via data attributes:

```html
<div id="lead-capture-form" 
     data-api-endpoint="https://your-api.com/leads"
     data-fields="name,email,company,phone"
     data-title="Contact Us"
     data-submit-text="Get Started"
     data-success-message="Thanks! We'll be in touch soon."
     data-theme="light">
</div>
```

### Available Fields

- `name` - Contact name (required)
- `email` - Email address (required, validated)
- `company` - Company name (optional)
- `phone` - Phone number (optional)
- `details` - Additional details (optional)

### Styling Options

- `data-theme="light|dark"` - Color scheme
- `data-width="full|compact"` - Form width
- `data-position="inline|modal"` - Display mode

## 🔒 Security Features

- Input validation and sanitization
- Rate limiting and spam protection
- CORS configuration for authorized domains
- Encrypted data storage
- Audit logging for all submissions

## 🔗 Integration Examples

### GitHub Pages (Jekyll)

```markdown
---
layout: default
title: Contact
---

# Get in Touch

{% include lead-capture-form.html 
   api_endpoint="https://your-api.com/leads"
   fields="name,email,details" %}
```

### Static Site Generators

#### Gatsby

```jsx
import React, { useEffect } from 'react';

const ContactPage = () => {
  useEffect(() => {
    // Load lead capture script
    const script = document.createElement('script');
    script.src = '/lead-capture.js';
    document.body.appendChild(script);
  }, []);

  return (
    <div>
      <h1>Contact Us</h1>
      <div id="lead-capture-form" 
           data-api-endpoint="https://your-api.com/leads"
           data-fields="name,email,company">
      </div>
    </div>
  );
};

export default ContactPage;
```

#### Next.js

```jsx
import { useEffect } from 'react';
import Script from 'next/script';

export default function Contact() {
  return (
    <>
      <h1>Contact Us</h1>
      <div id="lead-capture-form" 
           data-api-endpoint="https://your-api.com/leads"
           data-fields="name,email,company">
      </div>
      <Script src="/lead-capture.js" />
    </>
  );
}
```

## 🔮 Future Mautic Integration

This system is designed for seamless integration with Mautic marketing automation:

- **Compatible Data Format**: Lead data structure aligns with Mautic contact fields
- **Webhook Support**: Real-time lead notifications to Mautic
- **Bulk Export**: CSV/JSON export for Mautic import
- **Custom Fields**: Extensible field system for Mautic properties

## 📊 Monitoring & Analytics

- CloudWatch logging and metrics
- API Gateway usage analytics  
- DynamoDB performance monitoring
- Custom dashboards for lead tracking

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file for details.

## 🆘 Support

- 📖 [Documentation](../../docs/)
- 🐛 [Issue Tracker](https://github.com/Rho-Lall/mautic/issues)
- 💬 [Discussions](https://github.com/Rho-Lall/mautic/discussions)

## 🏷️ Version History

- **v1.0.0** - Initial release with basic lead capture functionality
- **v1.1.0** - Added custom field support and improved validation
- **v1.2.0** - Mautic integration preparation and webhook support

---

**Part of the Mautic Marketing Automation Suite**