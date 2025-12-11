#!/bin/bash

# Security Scanning and Validation Script for Mautic Public Modules
# This script implements automated scanning for hardcoded secrets, credentials,
# and validates that no actual resources would be created in development environments

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_MODULES_DIR="$MODULE_ROOT/terraform/modules"
DOCKER_DIR="$MODULE_ROOT/docker"
EXAMPLES_DIR="$MODULE_ROOT/examples"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Security scan results
SECURITY_ERRORS=0
SECURITY_WARNINGS=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to increment error count
add_security_error() {
    ((SECURITY_ERRORS++))
    log_error "$1"
}

# Function to increment warning count
add_security_warning() {
    ((SECURITY_WARNINGS++))
    log_warning "$1"
}

# Function to scan for hardcoded secrets and credentials
scan_hardcoded_secrets() {
    log_info "Scanning for hardcoded secrets and credentials..."
    
    # Define patterns for sensitive data detection
    local secret_patterns=(
        # AWS credentials
        "AKIA[0-9A-Z]{16}"                    # AWS Access Key ID
        "aws_access_key_id\s*=\s*['\"][^'\"]*['\"]"
        "aws_secret_access_key\s*=\s*['\"][^'\"]*['\"]"
        
        # Generic secrets
        "password\s*=\s*['\"][^'\"]{8,}['\"]"
        "secret\s*=\s*['\"][^'\"]{8,}['\"]"
        "api_key\s*=\s*['\"][^'\"]{8,}['\"]"
        "token\s*=\s*['\"][^'\"]{8,}['\"]"
        
        # Database credentials
        "db_password\s*=\s*['\"][^'\"]*['\"]"
        "database_password\s*=\s*['\"][^'\"]*['\"]"
        "mysql_password\s*=\s*['\"][^'\"]*['\"]"
        
        # Private keys
        "-----BEGIN PRIVATE KEY-----"
        "-----BEGIN RSA PRIVATE KEY-----"
        "-----BEGIN EC PRIVATE KEY-----"
        
        # Common hardcoded values that should be variables
        "arn:aws:iam::[0-9]{12}:"            # Hardcoded AWS account IDs
    )
    
    # Scan all relevant files
    local scan_dirs=("$TERRAFORM_MODULES_DIR" "$DOCKER_DIR" "$EXAMPLES_DIR")
    local files_scanned=0
    local secrets_found=0
    
    for dir in "${scan_dirs[@]}"; do
        if [ -d "$dir" ]; then
            while IFS= read -r -d '' file; do
                ((files_scanned++))
                
                for pattern in "${secret_patterns[@]}"; do
                    if grep -qiE "$pattern" "$file" 2>/dev/null; then
                        local relative_path="${file#$MODULE_ROOT/}"
                        add_security_error "Potential hardcoded secret found in $relative_path"
                        log_error "  Pattern: $pattern"
                        ((secrets_found++))
                    fi
                done
            done < <(find "$dir" -type f \( -name "*.tf" -o -name "*.tfvars" -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "Dockerfile" -o -name "*.sh" \) -print0)
        fi
    done
    
    if [ $secrets_found -eq 0 ]; then
        log_success "No hardcoded secrets detected in $files_scanned files"
    else
        log_error "Found $secrets_found potential hardcoded secrets in $files_scanned files"
    fi
}

# Function to validate placeholder usage
validate_placeholder_usage() {
    log_info "Validating placeholder usage consistency..."
    
    # Define required placeholder patterns
    local placeholder_patterns=(
        "var\."                              # Terraform variables
        "\${var\."                          # Terraform variable interpolation
        "PLACEHOLDER"                        # Explicit placeholder text
        "CHANGEME"                          # Change-me indicators
        "YOUR_"                             # Your-prefix indicators
        "EXAMPLE"                           # Example values
    )
    
    # Define forbidden hardcoded values
    local forbidden_patterns=(
        # Specific AWS account IDs
        "123456789012"
        "111122223333"
        
        # Specific resource names that should be variables
        "my-vpc"
        "my-subnet"
        "my-security-group"
        "production"
        "staging"
        "dev"
        
        # Specific domain names
        "example\.com"
        "test\.com"
        "mycompany\.com"
    )
    
    local files_checked=0
    local violations_found=0
    
    # Check Terraform modules for proper variable usage
    if [ -d "$TERRAFORM_MODULES_DIR" ]; then
        while IFS= read -r -d '' file; do
            ((files_checked++))
            
            # Check for forbidden hardcoded values
            for pattern in "${forbidden_patterns[@]}"; do
                if grep -qE "$pattern" "$file" 2>/dev/null; then
                    local relative_path="${file#$MODULE_ROOT/}"
                    add_security_warning "Hardcoded value found in $relative_path: $pattern"
                    ((violations_found++))
                fi
            done
            
            # Check that sensitive configurations use variables
            if grep -qE "(password|secret|key)" "$file" 2>/dev/null; then
                if ! grep -qE "var\.|PLACEHOLDER|CHANGEME" "$file" 2>/dev/null; then
                    local relative_path="${file#$MODULE_ROOT/}"
                    add_security_warning "Sensitive configuration without proper variable usage in $relative_path"
                    ((violations_found++))
                fi
            fi
        done < <(find "$TERRAFORM_MODULES_DIR" -name "*.tf" -print0)
    fi
    
    if [ $violations_found -eq 0 ]; then
        log_success "Placeholder usage validation passed for $files_checked files"
    else
        log_warning "Found $violations_found placeholder usage violations in $files_checked files"
    fi
}

# Function to validate resource creation prevention
validate_resource_creation_prevention() {
    log_info "Validating resource creation prevention safeguards..."
    
    local modules_checked=0
    local safeguards_missing=0
    
    # Check each Terraform module for development safeguards
    if [ -d "$TERRAFORM_MODULES_DIR" ]; then
        for module_dir in "$TERRAFORM_MODULES_DIR"/*; do
            if [ -d "$module_dir" ]; then
                local module_name=$(basename "$module_dir")
                ((modules_checked++))
                
                # Check for main.tf file
                if [ -f "$module_dir/main.tf" ]; then
                    # Look for development environment checks
                    if ! grep -qE "(var\.environment|var\.create_resources|count\s*=\s*var\.|for_each\s*=\s*var\.)" "$module_dir/main.tf" 2>/dev/null; then
                        add_security_warning "Module $module_name lacks resource creation safeguards"
                        ((safeguards_missing++))
                    fi
                    
                    # Check for proper variable validation
                    if [ -f "$module_dir/variables.tf" ]; then
                        if ! grep -qE "validation\s*{" "$module_dir/variables.tf" 2>/dev/null; then
                            add_security_warning "Module $module_name lacks input validation"
                            ((safeguards_missing++))
                        fi
                    else
                        add_security_error "Module $module_name missing variables.tf file"
                        ((safeguards_missing++))
                    fi
                else
                    add_security_error "Module $module_name missing main.tf file"
                    ((safeguards_missing++))
                fi
            fi
        done
    fi
    
    if [ $safeguards_missing -eq 0 ]; then
        log_success "Resource creation prevention validated for $modules_checked modules"
    else
        log_warning "Found $safeguards_missing modules with missing safeguards"
    fi
}

# Function to validate Terraform module security
validate_terraform_security() {
    log_info "Validating Terraform module security configurations..."
    
    local modules_checked=0
    local security_issues=0
    
    if [ -d "$TERRAFORM_MODULES_DIR" ]; then
        for module_dir in "$TERRAFORM_MODULES_DIR"/*; do
            if [ -d "$module_dir" ]; then
                local module_name=$(basename "$module_dir")
                ((modules_checked++))
                
                log_info "Checking security for module: $module_name"
                
                # Run terraform validate if terraform is available
                if command -v terraform &> /dev/null; then
                    cd "$module_dir"
                    if terraform validate &> /dev/null; then
                        log_success "Module $module_name: Terraform syntax valid"
                    else
                        add_security_error "Module $module_name: Terraform validation failed"
                        ((security_issues++))
                    fi
                fi
                
                # Check for security best practices
                if [ -f "$module_dir/main.tf" ]; then
                    # Check for encryption configurations
                    if grep -qE "(encrypt|kms|ssl)" "$module_dir/main.tf" 2>/dev/null; then
                        log_success "Module $module_name: Encryption configurations found"
                    else
                        add_security_warning "Module $module_name: No encryption configurations detected"
                        ((security_issues++))
                    fi
                    
                    # Check for security group configurations
                    if grep -qE "aws_security_group" "$module_dir/main.tf" 2>/dev/null; then
                        # Ensure no overly permissive rules
                        if grep -qE "0\.0\.0\.0/0.*22|0\.0\.0\.0/0.*3389" "$module_dir/main.tf" 2>/dev/null; then
                            add_security_error "Module $module_name: Overly permissive security group rules detected"
                            ((security_issues++))
                        else
                            log_success "Module $module_name: Security group rules appear secure"
                        fi
                    fi
                fi
            fi
        done
    fi
    
    if [ $security_issues -eq 0 ]; then
        log_success "Security validation passed for $modules_checked modules"
    else
        log_warning "Found $security_issues security issues across $modules_checked modules"
    fi
}

# Function to validate Docker security
validate_docker_security() {
    log_info "Validating Docker configuration security..."
    
    local docker_files_checked=0
    local docker_issues=0
    
    if [ -d "$DOCKER_DIR" ]; then
        # Check Dockerfile
        if [ -f "$DOCKER_DIR/Dockerfile" ]; then
            ((docker_files_checked++))
            
            # Check for security best practices
            if grep -qE "^USER\s+" "$DOCKER_DIR/Dockerfile" 2>/dev/null; then
                log_success "Dockerfile: Non-root user configuration found"
            else
                add_security_warning "Dockerfile: Consider adding non-root user configuration"
                ((docker_issues++))
            fi
            
            # Check for hardcoded secrets
            if grep -qiE "(password|secret|key|token)\s*=" "$DOCKER_DIR/Dockerfile" 2>/dev/null; then
                add_security_error "Dockerfile: Potential hardcoded secrets detected"
                ((docker_issues++))
            else
                log_success "Dockerfile: No hardcoded secrets detected"
            fi
            
            # Check for proper base image usage
            if grep -qE "^FROM\s+mautic/mautic:" "$DOCKER_DIR/Dockerfile" 2>/dev/null; then
                log_success "Dockerfile: Using official Mautic base image"
            else
                add_security_warning "Dockerfile: Not using official Mautic base image"
                ((docker_issues++))
            fi
        fi
        
        # Check configuration files
        if [ -d "$DOCKER_DIR/config" ]; then
            while IFS= read -r -d '' file; do
                ((docker_files_checked++))
                
                # Check for hardcoded credentials
                if grep -qiE "(password|secret|key)\s*=" "$file" 2>/dev/null; then
                    local relative_path="${file#$MODULE_ROOT/}"
                    add_security_error "Docker config: Hardcoded credentials in $relative_path"
                    ((docker_issues++))
                fi
            done < <(find "$DOCKER_DIR/config" -type f -print0)
        fi
    fi
    
    if [ $docker_issues -eq 0 ]; then
        log_success "Docker security validation passed for $docker_files_checked files"
    else
        log_warning "Found $docker_issues Docker security issues in $docker_files_checked files"
    fi
}

# Function to validate development environment safeguards
validate_development_safeguards() {
    log_info "Validating development environment safeguards..."
    
    local safeguards_checked=0
    local missing_safeguards=0
    
    # Check for environment-based resource creation controls
    if [ -d "$TERRAFORM_MODULES_DIR" ]; then
        for module_dir in "$TERRAFORM_MODULES_DIR"/*; do
            if [ -d "$module_dir" ] && [ -f "$module_dir/variables.tf" ]; then
                local module_name=$(basename "$module_dir")
                ((safeguards_checked++))
                
                # Check for environment variable with validation
                if grep -qE "variable\s+['\"]environment['\"]" "$module_dir/variables.tf" 2>/dev/null; then
                    if grep -A 10 "variable\s+['\"]environment['\"]" "$module_dir/variables.tf" | grep -qE "validation\s*{" 2>/dev/null; then
                        log_success "Module $module_name: Environment validation found"
                    else
                        add_security_warning "Module $module_name: Environment variable lacks validation"
                        ((missing_safeguards++))
                    fi
                else
                    add_security_warning "Module $module_name: No environment variable defined"
                    ((missing_safeguards++))
                fi
                
                # Check for create_resources toggle
                if grep -qE "variable\s+['\"]create_resources['\"]" "$module_dir/variables.tf" 2>/dev/null; then
                    log_success "Module $module_name: Resource creation toggle found"
                else
                    add_security_warning "Module $module_name: No resource creation toggle"
                    ((missing_safeguards++))
                fi
            fi
        done
    fi
    
    # Check examples for proper safeguards
    if [ -d "$EXAMPLES_DIR" ]; then
        for example_dir in "$EXAMPLES_DIR"/*; do
            if [ -d "$example_dir" ] && [ -f "$example_dir/main.tf" ]; then
                local example_name=$(basename "$example_dir")
                ((safeguards_checked++))
                
                # Check for development environment settings
                if grep -qE "environment\s*=\s*['\"]dev['\"]" "$example_dir/main.tf" 2>/dev/null; then
                    log_success "Example $example_name: Development environment configured"
                else
                    add_security_warning "Example $example_name: Should use development environment"
                    ((missing_safeguards++))
                fi
                
                # Check for resource creation disabled
                if grep -qE "create_resources\s*=\s*false" "$example_dir/main.tf" 2>/dev/null; then
                    log_success "Example $example_name: Resource creation disabled"
                else
                    add_security_warning "Example $example_name: Should disable resource creation"
                    ((missing_safeguards++))
                fi
            fi
        done
    fi
    
    if [ $missing_safeguards -eq 0 ]; then
        log_success "Development safeguards validated for $safeguards_checked components"
    else
        log_warning "Found $missing_safeguards missing development safeguards"
    fi
}

# Function to generate security report
generate_security_report() {
    local report_file="$MODULE_ROOT/security-scan-report.txt"
    
    log_info "Generating security scan report..."
    
    cat > "$report_file" << EOF
Mautic Public Modules - Security Scan Report
============================================
Generated: $(date)
Scan Location: $MODULE_ROOT

SUMMARY
-------
Security Errors: $SECURITY_ERRORS
Security Warnings: $SECURITY_WARNINGS

SCAN RESULTS
-----------
✓ Hardcoded Secrets Scan
✓ Placeholder Usage Validation  
✓ Resource Creation Prevention Check
✓ Terraform Module Security Validation
✓ Docker Configuration Security Check
✓ Development Environment Safeguards Check

RECOMMENDATIONS
--------------
EOF

    if [ $SECURITY_ERRORS -gt 0 ]; then
        cat >> "$report_file" << EOF
❌ CRITICAL: $SECURITY_ERRORS security errors must be fixed before release
EOF
    fi
    
    if [ $SECURITY_WARNINGS -gt 0 ]; then
        cat >> "$report_file" << EOF
⚠️  WARNING: $SECURITY_WARNINGS security warnings should be reviewed
EOF
    fi
    
    if [ $SECURITY_ERRORS -eq 0 ] && [ $SECURITY_WARNINGS -eq 0 ]; then
        cat >> "$report_file" << EOF
✅ All security validations passed successfully
EOF
    fi
    
    cat >> "$report_file" << EOF

NEXT STEPS
----------
1. Review and fix any security errors
2. Address security warnings where applicable
3. Run security scan again after fixes
4. Proceed with module testing and validation

For more information, see the security documentation.
EOF
    
    log_success "Security report generated: $report_file"
}

# Function to show security scan summary
show_security_summary() {
    echo
    log_info "Security Scan Summary:"
    echo "====================="
    
    if [ $SECURITY_ERRORS -eq 0 ] && [ $SECURITY_WARNINGS -eq 0 ]; then
        log_success "All security validations passed! Modules are secure for public release."
    elif [ $SECURITY_ERRORS -eq 0 ]; then
        log_warning "Security scan completed with $SECURITY_WARNINGS warning(s). Review warnings before release."
    else
        log_error "Security scan failed with $SECURITY_ERRORS error(s) and $SECURITY_WARNINGS warning(s)."
        log_error "Please fix all security errors before public release."
        exit 1
    fi
}

# Main security scan function
main() {
    log_info "Starting comprehensive security scan for Mautic public modules..."
    echo
    
    scan_hardcoded_secrets
    echo
    validate_placeholder_usage
    echo
    validate_resource_creation_prevention
    echo
    validate_terraform_security
    echo
    validate_docker_security
    echo
    validate_development_safeguards
    echo
    
    generate_security_report
    show_security_summary
}

# Parse command line arguments
case "${1:-}" in
    "secrets")
        scan_hardcoded_secrets
        ;;
    "placeholders")
        validate_placeholder_usage
        ;;
    "resources")
        validate_resource_creation_prevention
        ;;
    "terraform")
        validate_terraform_security
        ;;
    "docker")
        validate_docker_security
        ;;
    "safeguards")
        validate_development_safeguards
        ;;
    "report")
        generate_security_report
        ;;
    "")
        main
        ;;
    *)
        echo "Usage: $0 [secrets|placeholders|resources|terraform|docker|safeguards|report]"
        echo "  secrets      - Scan for hardcoded secrets and credentials"
        echo "  placeholders - Validate placeholder usage consistency"
        echo "  resources    - Check resource creation prevention safeguards"
        echo "  terraform    - Validate Terraform module security"
        echo "  docker       - Validate Docker configuration security"
        echo "  safeguards   - Check development environment safeguards"
        echo "  report       - Generate security report only"
        echo "  (no args)    - Run full security scan"
        exit 1
        ;;
esac