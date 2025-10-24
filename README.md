# Mautic Marketing Automation Suite

A comprehensive marketing automation platform with serverless integrations and self-hosted Mautic server capabilities. This repository contains multiple products designed to work together for complete marketing automation workflows.

## 🏗️ Products

### 🚀 Serverless Lead Capture
A serverless lead capture form system that can be embedded into GitHub Pages websites and deployed on AWS infrastructure.

**Location**: [`serverless/lead-capture/`](serverless/lead-capture/)

**Features**:
- Embeddable forms for static websites
- AWS serverless architecture (Lambda + API Gateway + DynamoDB)
- Real-time lead capture and validation
- Future Mautic integration ready

### 🖥️ Mautic Server (Coming Soon)
Self-hosted Mautic marketing automation server with custom configurations and integrations.

**Location**: `mautic-server/` (planned)

**Features**:
- Docker-based Mautic deployment
- Custom themes and plugins
- Integration with serverless components
- Advanced automation workflows

### 🔗 n8n Automation Workflows (Coming Soon)
Serverless n8n workflows for marketing automation and data processing.

**Location**: `serverless/n8n-workflows/` (planned)

**Features**:
- Serverless n8n on AWS Fargate
- Marketing automation workflows
- Data synchronization between services
- Cost-effective infrequent execution

## 🚀 Quick Start

### Serverless Lead Capture

```bash
# Navigate to the lead capture project
cd serverless/lead-capture

# Install dependencies
npm install

# Build and deploy
npm run deploy:dev
```

See [`serverless/lead-capture/README.md`](serverless/lead-capture/README.md) for detailed setup instructions.

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

## 📁 Repository Structure

```
├── serverless/                 # Serverless components
│   ├── lead-capture/           # Lead capture form system
│   │   ├── src/                # Source code
│   │   ├── terraform/          # Infrastructure as code
│   │   ├── docs/               # Product documentation
│   │   └── package.json        # Dependencies and scripts
│   └── n8n-workflows/          # n8n automation workflows (planned)
├── mautic-server/              # Self-hosted Mautic server (planned)
│   ├── docker/                 # Docker configurations
│   ├── themes/                 # Custom themes
│   └── plugins/                # Custom plugins
├── docs/                       # Shared documentation
│   └── installation-guides/   # Setup guides
└── .kiro/                      # Kiro IDE specifications
    └── specs/                  # Feature specifications
```

## 🛠️ Development Setup

### Prerequisites

- Node.js 18+ (for serverless components)
- AWS CLI configured
- Terraform installed
- Docker (for Mautic server)
- AWS account with appropriate permissions

### 📋 Installation Guides

**Step-by-step setup guides are available in the [`docs/installation-guides/`](docs/installation-guides/) directory:**

1. **[AWS CLI Setup](docs/installation-guides/aws-cli-setup.md)** - Configure AWS CLI and credentials
2. **[Terraform Backend Setup](docs/installation-guides/terraform-backend-setup.md)** - Set up Terraform state management
3. **[Domain Setup](docs/installation-guides/domain-setup.md)** - Configure custom domains (optional)
4. **[Private Repository Setup](docs/deployment/private-repo-setup.md)** - Set up private repo for production deployment

### Getting Started

**Development Workflow:**
1. **Complete AWS Prerequisites** - Follow installation guides 1-3 above
2. **Set up Private Repository** - Follow the [Private Repository Setup Guide](docs/deployment/private-repo-setup.md)
3. **Deploy to Development** - Test your configuration in a dev environment
4. **Deploy to Production** - Deploy with full security and monitoring

**Product-Specific Instructions:**
- **Serverless Lead Capture**: See [`serverless/lead-capture/README.md`](serverless/lead-capture/README.md)
- **Mautic Server**: Coming soon
- **n8n Workflows**: Coming soon

### 🚀 Quick Start for Lead Capture

**For website owners who just want to add a form:**
1. Download `lead-capture.js` and `lead-capture.css` from [`serverless/lead-capture/src/client/`](serverless/lead-capture/src/client/)
2. Follow the [Integration Guide](serverless/lead-capture/docs/integration.md)
3. Add the form to your website in minutes

**For developers who want to deploy the full system:**
1. **Complete AWS Prerequisites** - Follow [installation guides](docs/installation-guides/) (steps 1-3)
2. **Set up Private Repository** - Follow the [Private Repository Setup Guide](docs/deployment/private-repo-setup.md)
3. **Deploy Infrastructure** - Use the private repo to deploy your own API endpoint
4. **Integrate Form** - Connect your website to your deployed API

> **Next Step**: After completing the AWS setup, follow the [Private Repository Setup Guide](docs/deployment/private-repo-setup.md) to create your production deployment repository.

## 🏗️ Architecture Overview

### Serverless Components
- **Lead Capture**: AWS Lambda + API Gateway + DynamoDB
- **n8n Workflows**: AWS Fargate + ECS (serverless containers)
- **Shared Infrastructure**: Route 53, Certificate Manager, CloudWatch

### Self-Hosted Components  
- **Mautic Server**: Docker-based deployment with custom configurations
- **Database**: MySQL/MariaDB for Mautic data
- **File Storage**: S3 integration for assets and backups

### Integration Flow
```
Static Website → Serverless Lead Capture → Mautic Server → n8n Workflows
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📖 [Documentation](docs/)
- 🐛 [Issue Tracker](https://github.com/yourusername/serverless-lead-capture/issues)
- 💬 [Discussions](https://github.com/yourusername/serverless-lead-capture/discussions)

## 🏷️ Version History

- **v1.0.0** - Initial release with basic lead capture functionality
- **v1.1.0** - Added custom field support and improved validation
- **v1.2.0** - Mautic integration preparation and webhook support

---

**Built with ❤️ for the open source community**