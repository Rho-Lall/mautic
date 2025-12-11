# Vanilla Mautic Docker Configuration
# This Dockerfile extends the official Mautic image without modifications

FROM mautic/mautic:latest

# Metadata
LABEL maintainer="DevOps Team"
LABEL description="Vanilla Mautic container for AWS deployment"
LABEL version="1.0"

# Environment variables for Mautic configuration
# Database connection settings
ENV MAUTIC_DB_HOST="PLACEHOLDER_DB_HOST"
ENV MAUTIC_DB_PORT="3306"
ENV MAUTIC_DB_NAME="PLACEHOLDER_DB_NAME"
ENV MAUTIC_DB_USER="PLACEHOLDER_DB_USER"
ENV MAUTIC_DB_PASS="PLACEHOLDER_DB_PASS"

# Mautic application settings
ENV MAUTIC_TRUSTED_HOSTS="PLACEHOLDER_TRUSTED_HOSTS"
ENV MAUTIC_SECRET_KEY="PLACEHOLDER_SECRET_KEY"
ENV MAUTIC_SITE_URL="PLACEHOLDER_SITE_URL"

# Additional configuration variables
ENV MAUTIC_ADMIN_EMAIL="PLACEHOLDER_ADMIN_EMAIL"
ENV MAUTIC_ADMIN_PASS="PLACEHOLDER_ADMIN_PASS"

# Health check configuration
# Use a more reliable health check that doesn't depend on curl
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD php -r "echo 'Health check: '; if (file_exists('/var/www/html/index.php')) { echo 'OK'; exit(0); } else { echo 'FAIL'; exit(1); }"

# Expose port 80 for HTTP traffic
EXPOSE 80

# Use the default entrypoint and command from the base image
# No custom modifications to maintain vanilla configuration