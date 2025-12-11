# Vanilla Mautic Docker Configuration

This directory contains a vanilla Docker configuration for Mautic that extends the official Mautic image without any custom plugins or themes.

## Overview

The configuration provides:
- A basic Dockerfile extending the official Mautic image
- Essential PHP and Apache configuration templates
- Environment variable-based configuration
- Basic health check implementation

## Files

- `Dockerfile` - Main Docker configuration extending mautic/mautic:latest
- `config/php.ini` - Essential PHP performance and security settings
- `config/apache.conf` - Basic Apache configuration with minimal optimizations

## Environment Variables

The following environment variables are supported for configuration:

### Database Configuration
- `MAUTIC_DB_HOST` - Database hostname
- `MAUTIC_DB_PORT` - Database port (default: 3306)
- `MAUTIC_DB_NAME` - Database name
- `MAUTIC_DB_USER` - Database username
- `MAUTIC_DB_PASSWORD` - Database password

### Application Configuration
- `MAUTIC_TRUSTED_HOSTS` - Comma-separated list of trusted hosts
- `MAUTIC_SECRET_KEY` - Secret key for Mautic encryption
- `MAUTIC_SITE_URL` - Base URL for the Mautic installation
- `MAUTIC_ADMIN_EMAIL` - Admin user email
- `MAUTIC_ADMIN_PASSWORD` - Admin user password

## Building the Image

```bash
docker build -t mautic-vanilla .
```

## Running the Container

```bash
docker run -d \
  -p 80:80 \
  -e MAUTIC_DB_HOST=your-db-host \
  -e MAUTIC_DB_NAME=mautic \
  -e MAUTIC_DB_USER=mautic_user \
  -e MAUTIC_DB_PASSWORD=your-password \
  -e MAUTIC_TRUSTED_HOSTS=your-domain.com \
  mautic-vanilla
```

## Health Check

The container includes a health check that verifies the Mautic installation files are present. The health check runs every 30 seconds with a 2-minute startup period.

## Security Features

- No custom plugins or themes included
- Essential security headers configured
- PHP security hardening applied
- Minimal attack surface maintained

## Performance Optimizations

Only essential performance optimizations are included:
- OPcache configuration
- Gzip compression
- Static asset caching
- Realpath cache optimization

## Compliance

This configuration meets the following requirements:
- Extends official Mautic image without modifications (Requirement 2.1)
- Supports environment variable-based configuration (Requirement 2.2)
- Includes basic health check configuration (Requirement 2.3)
- Uses default Mautic installation without custom plugins or themes (Requirement 2.4)
- Includes only essential PHP and Apache configurations (Requirement 2.5)