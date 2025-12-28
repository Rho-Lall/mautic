# Mautic Docker Build Pipeline

This directory contains the Docker build pipeline for creating production-ready Mautic images that extend the public Mautic modules base image.

## Directory Structure

```
docker/
├── Dockerfile                      # Production Mautic Dockerfile
├── config/                         # Production configuration files
│   ├── production-php.ini          # Enhanced PHP settings for production
│   ├── production-apache.conf      # Enhanced Apache settings for production
│   ├── mautic-local.php           # Mautic configuration template
│   └── mautic-logrotate           # Log rotation configuration
├── scripts/
│   └── production-startup.sh      # Production container startup script
└── README.md                      # This file
```

## Build Process

The build process creates custom Mautic images that extend the vanilla public modules base image with production-specific optimizations:

### 1. Base Image Extension

The Dockerfile extends the public modules base image (`public-modules-mautic-base:latest`) with:

- **Production dependencies**: Monitoring tools, log management utilities
- **Enhanced configurations**: Optimized PHP and Apache settings for production workloads
- **Security hardening**: Additional security headers and file permissions
- **Logging infrastructure**: Centralized logging with rotation policies
- **Health checks**: Enhanced health monitoring for production environments

### 2. Configuration Management

Production configurations include:

- **PHP Settings**: Increased memory limits, enhanced OPcache, production error handling
- **Apache Settings**: Security headers, compression, caching, performance tuning
- **Mautic Configuration**: Production-specific settings with environment variable substitution
- **Log Management**: Structured logging with automatic rotation

### 3. Environment Variable Substitution

The startup script processes configuration templates and substitutes environment variables:

**Required Variables:**
- `MAUTIC_DB_HOST` - Database hostname
- `MAUTIC_DB_NAME` - Database name
- `MAUTIC_DB_USER` - Database username
- `MAUTIC_DB_PASS` - Database password
- `MAUTIC_SECRET_KEY` - Mautic secret key
- `MAUTIC_SITE_URL` - Mautic site URL

**Optional Variables:**
- `MAUTIC_DB_PORT` - Database port (default: 3306)
- `MAUTIC_TRUSTED_HOSTS` - Trusted hosts (default: localhost)
- `MAUTIC_SMTP_*` - SMTP configuration for email sending
- `MAUTIC_REMEMBER_KEY` - Remember me functionality key

## Build Scripts

### build-images.sh

Automated Docker image building script that:

1. **Builds base image** from public modules
2. **Builds custom image** extending the base with production configurations
3. **Tags images** with environment, timestamp, and git commit
4. **Optionally pushes** to ECR registry

**Usage:**
```bash
# Build development image
./scripts/build-images.sh dev

# Build and push production image
./scripts/build-images.sh prod --push --aws-account 123456789

# Build with custom build arguments
./scripts/build-images.sh test --build-arg CUSTOM_VAR=value
```

**Features:**
- Environment-specific builds (dev, test, prod)
- Automatic image tagging with timestamps and git commits
- ECR integration with automatic repository creation
- Build argument support for customization
- Comprehensive logging and error handling

### push.sh

Dedicated ECR push script that:

1. **Validates** local images and AWS credentials
2. **Authenticates** with ECR registry
3. **Creates** ECR repository if needed with lifecycle policies
4. **Tags and pushes** images with multiple tags
5. **Manages** image retention policies

**Usage:**
```bash
# Push development image
./scripts/push.sh dev --aws-account 123456789

# Force push existing image
./scripts/push.sh prod --force --aws-account 123456789

# Push to specific region
./scripts/push.sh test --aws-region eu-west-1 --aws-account 123456789
```

**Features:**
- Automatic ECR repository creation with lifecycle policies
- Image retention management (keeps last N images per environment)
- Duplicate image detection and prevention
- Multi-tag pushing (environment, timestamp, commit, latest)
- Comprehensive validation and error handling

## Image Tags

Images are tagged with multiple formats for different use cases:

- **Environment tag**: `mautic-server-custom:dev|test|prod`
- **Timestamped tag**: `mautic-server-custom:prod-20231213-143022`
- **Commit tag**: `mautic-server-custom:prod-abc1234`
- **Latest tag**: `mautic-server-custom:latest` (production only)

## ECR Integration

### Repository Management

The scripts automatically:
- Create ECR repositories if they don't exist
- Configure image scanning for security
- Set up lifecycle policies for image retention
- Enable encryption at rest

### Lifecycle Policies

Automatic cleanup policies:
- **Production**: Keep last 10 images
- **Test**: Keep last 5 images
- **Development**: Keep last 3 images
- **Untagged**: Delete after 1 day

### Security Features

- Image vulnerability scanning enabled
- Encryption at rest with AES256
- IAM-based access control
- Secure authentication via AWS CLI

## Production Optimizations

### Performance Enhancements

- **PHP OPcache**: Optimized for production workloads
- **Apache compression**: GZIP compression for static assets
- **Caching headers**: Long-term caching for static resources
- **Memory management**: Increased limits for large operations

### Security Hardening

- **Security headers**: HSTS, CSP, XSS protection, frame options
- **File permissions**: Restricted access to sensitive files
- **Error handling**: Production error logging without exposure
- **Session security**: Secure session configuration

### Monitoring and Logging

- **Health checks**: Enhanced health monitoring endpoints
- **Structured logging**: Centralized log management
- **Log rotation**: Automatic log cleanup and archival
- **Performance monitoring**: Built-in monitoring tools

## Development Workflow

1. **Modify configurations** in the `config/` directory
2. **Update Dockerfile** if needed for new dependencies
3. **Test locally** with development environment
4. **Build and test** with `build-images.sh dev`
5. **Deploy to test** environment for validation
6. **Build production** image with `build-images.sh prod`
7. **Push to ECR** with `push.sh prod --push`

## Troubleshooting

### Common Issues

**Build failures:**
- Ensure public modules submodule is up to date
- Check Docker daemon is running
- Verify base image is available

**Push failures:**
- Validate AWS credentials and permissions
- Check ECR repository permissions
- Ensure correct AWS region configuration

**Runtime issues:**
- Verify all required environment variables are set
- Check database connectivity
- Review container logs for startup errors

### Debugging

**View build logs:**
```bash
docker build --no-cache -t debug-image .
```

**Inspect image:**
```bash
docker run -it mautic-server-custom:dev /bin/bash
```

**Check container logs:**
```bash
docker logs <container-id>
```

## Integration with Terraform

The built images integrate with Terraform ECS deployments:

```hcl
# Reference ECR image in Terraform
module "mautic_service" {
  source = "../../../public-modules/mautic-server/terraform/modules/mautic-service"
  
  image_uri = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/mautic-server-custom:${var.environment}"
  # ... other configuration
}
```

This ensures consistent image deployment across all environments while maintaining separation between build and deployment processes.