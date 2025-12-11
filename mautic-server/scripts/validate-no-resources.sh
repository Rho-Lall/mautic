#!/bin/bash

# Resource Creation Prevention Validation Script
# This script validates that Terraform modules will not create actual resources
# when used in development/testing environments

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_MODULES_DIR="$MODULE_ROOT/terraform/modules"
EXAMPLES_DIR="$MODULE_ROOT/examples"
TEMP_DIR="/tmp/mautic-validation-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validation results
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

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
add_error() {
    ((VALIDATION_ERRORS++))
    log_error "$1"
}

# Function to increment warning count
add_warning() {
    ((VALIDATION_WARNINGS++))
    log_warning "$1"
}

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Function to create test configuration for a module
create_test_config() {
    local module_name="$1"
    local test_dir="$2"
    
    mkdir -p "$test_dir"
    
    cat > "$test_dir/main.tf" << EOF
# Test configuration for $module_name module
# This should create zero resources when create_resources = false

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS provider for testing (no actual resources will be created)
provider "aws" {
  region = "us-east-1"
  
  # Skip credentials validation for testing
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  
  # Use fake endpoints to prevent actual AWS calls
  endpoints {
    ec2 = "http://localhost:4566"
    rds = "http://localhost:4566"
    elbv2 = "http://localhost:4566"
  }
}

module "$module_name" {
  source = "../../../terraform/modules/$module_name"
  
  # Security safeguards - prevent resource creation
  create_resources = false
  environment      = "dev"
  project_name     = "test-project"
  
  tags = {
    Environment = "dev"
    Testing     = "true"
  }
}

# Output validation - should handle null values gracefully
output "test_outputs" {
  description = "Test outputs from $module_name module"
  value = {
    module_outputs = module.$module_name
  }
}
EOF

    cat > "$test_dir/terraform.tf" << EOF
# Backend configuration for testing
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
EOF
}

# Function to validate module prevents resource creation
validate_module_no_resources() {
    local module_name="$1"
    local module_dir="$TERRAFORM_MODULES_DIR/$module_name"
    
    if [ ! -d "$module_dir" ]; then
        add_error "Module directory not found: $module_name"
        return
    fi
    
    log_info "Validating resource prevention for module: $module_name"
    
    # Create test directory
    local test_dir="$TEMP_DIR/$module_name"
    create_test_config "$module_name" "$test_dir"
    
    cd "$test_dir"
    
    # Initialize Terraform
    if ! terraform init -no-color &> init.log; then
        add_error "Module $module_name: Terraform init failed"
        cat init.log
        return
    fi
    
    # Validate configuration
    if ! terraform validate -no-color &> validate.log; then
        add_error "Module $module_name: Terraform validate failed"
        cat validate.log
        return
    fi
    
    # Plan with create_resources = false
    if ! terraform plan -no-color -out=plan.out &> plan.log; then
        add_error "Module $module_name: Terraform plan failed"
        cat plan.log
        return
    fi
    
    # Check that no resources will be created
    local resources_to_create=$(terraform show -no-color plan.out | grep -c "will be created" || true)
    local resources_to_change=$(terraform show -no-color plan.out | grep -c "will be updated" || true)
    local resources_to_destroy=$(terraform show -no-color plan.out | grep -c "will be destroyed" || true)
    
    if [ "$resources_to_create" -eq 0 ] && [ "$resources_to_change" -eq 0 ] && [ "$resources_to_destroy" -eq 0 ]; then
        log_success "Module $module_name: No resources will be created/modified/destroyed ✓"
    else
        add_error "Module $module_name: Would create $resources_to_create, change $resources_to_change, destroy $resources_to_destroy resources"
        log_error "Plan output:"
        terraform show -no-color plan.out | head -50
    fi
    
    # Test with create_resources = true to ensure module works when enabled
    log_info "Testing module $module_name with create_resources = true (should show resources to create)"
    
    # Update configuration to enable resource creation
    sed -i 's/create_resources = false/create_resources = true/' main.tf
    
    if terraform plan -no-color -out=plan-enabled.out &> plan-enabled.log; then
        local enabled_resources=$(terraform show -no-color plan-enabled.out | grep -c "will be created" || true)
        if [ "$enabled_resources" -gt 0 ]; then
            log_success "Module $module_name: Would create $enabled_resources resources when enabled ✓"
        else
            add_warning "Module $module_name: No resources to create even when enabled"
        fi
    else
        add_warning "Module $module_name: Plan failed when create_resources = true"
    fi
}

# Function to validate examples use development settings
validate_examples_dev_settings() {
    log_info "Validating example configurations use development settings..."
    
    if [ ! -d "$EXAMPLES_DIR" ]; then
        add_warning "Examples directory not found: $EXAMPLES_DIR"
        return
    fi
    
    for example_dir in "$EXAMPLES_DIR"/*; do
        if [ -d "$example_dir" ] && [ -f "$example_dir/main.tf" ]; then
            local example_name=$(basename "$example_dir")
            log_info "Checking example: $example_name"
            
            # Check for development environment setting
            if grep -q 'environment.*=.*"dev"' "$example_dir/main.tf"; then
                log_success "Example $example_name: Uses development environment ✓"
            else
                add_warning "Example $example_name: Should use environment = \"dev\""
            fi
            
            # Check for disabled resource creation
            if grep -q 'create_resources.*=.*false' "$example_dir/main.tf"; then
                log_success "Example $example_name: Resource creation disabled ✓"
            else
                add_warning "Example $example_name: Should set create_resources = false"
            fi
            
            # Check for test/development tags
            if grep -q -i 'testing\|development\|dev' "$example_dir/main.tf"; then
                log_success "Example $example_name: Contains development/testing indicators ✓"
            else
                add_warning "Example $example_name: Should include development/testing tags"
            fi
        fi
    done
}

# Function to validate variable constraints
validate_variable_constraints() {
    log_info "Validating variable constraints prevent resource creation in dev..."
    
    for module_dir in "$TERRAFORM_MODULES_DIR"/*; do
        if [ -d "$module_dir" ]; then
            local module_name=$(basename "$module_dir")
            
            if [ -f "$module_dir/variables.tf" ]; then
                # Check for create_resources variable
                if grep -q 'variable.*"create_resources"' "$module_dir/variables.tf"; then
                    log_success "Module $module_name: Has create_resources variable ✓"
                    
                    # Check for validation that prevents creation in dev
                    if grep -A 10 'variable.*"create_resources"' "$module_dir/variables.tf" | grep -q 'validation.*environment.*dev'; then
                        log_success "Module $module_name: Has dev environment validation ✓"
                    else
                        add_warning "Module $module_name: Should validate create_resources = false in dev environment"
                    fi
                else
                    add_error "Module $module_name: Missing create_resources variable"
                fi
                
                # Check for environment variable with validation
                if grep -q 'variable.*"environment"' "$module_dir/variables.tf"; then
                    if grep -A 10 'variable.*"environment"' "$module_dir/variables.tf" | grep -q 'validation'; then
                        log_success "Module $module_name: Has environment validation ✓"
                    else
                        add_warning "Module $module_name: Environment variable should have validation"
                    fi
                else
                    add_error "Module $module_name: Missing environment variable"
                fi
            else
                add_error "Module $module_name: Missing variables.tf file"
            fi
        fi
    done
}

# Function to check for hardcoded production values
check_hardcoded_values() {
    log_info "Checking for hardcoded production values..."
    
    local forbidden_patterns=(
        "prod"
        "production" 
        "staging"
        "123456789012"  # Example AWS account ID
        "arn:aws:iam::[0-9]{12}:"  # Hardcoded ARNs
    )
    
    local files_checked=0
    local violations_found=0
    
    for module_dir in "$TERRAFORM_MODULES_DIR"/*; do
        if [ -d "$module_dir" ]; then
            while IFS= read -r -d '' file; do
                ((files_checked++))
                
                for pattern in "${forbidden_patterns[@]}"; do
                    if grep -qE "$pattern" "$file" 2>/dev/null; then
                        local relative_path="${file#$MODULE_ROOT/}"
                        add_warning "Hardcoded value '$pattern' found in $relative_path"
                        ((violations_found++))
                    fi
                done
            done < <(find "$module_dir" -name "*.tf" -print0)
        fi
    done
    
    if [ $violations_found -eq 0 ]; then
        log_success "No hardcoded production values found in $files_checked files ✓"
    else
        log_warning "Found $violations_found hardcoded values in $files_checked files"
    fi
}

# Function to show validation summary
show_validation_summary() {
    echo
    log_info "Resource Creation Prevention Validation Summary:"
    echo "==============================================="
    
    if [ $VALIDATION_ERRORS -eq 0 ] && [ $VALIDATION_WARNINGS -eq 0 ]; then
        log_success "All validations passed! Modules are safe for public release."
        log_success "No resources will be created in development environments."
    elif [ $VALIDATION_ERRORS -eq 0 ]; then
        log_warning "Validation completed with $VALIDATION_WARNINGS warning(s)."
        log_warning "Review warnings to improve development safety."
    else
        log_error "Validation failed with $VALIDATION_ERRORS error(s) and $VALIDATION_WARNINGS warning(s)."
        log_error "Fix all errors before public release to prevent accidental resource creation."
        exit 1
    fi
}

# Main validation function
main() {
    log_info "Starting resource creation prevention validation..."
    echo
    
    # Check if terraform is available
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Validate each module
    for module_dir in "$TERRAFORM_MODULES_DIR"/*; do
        if [ -d "$module_dir" ]; then
            local module_name=$(basename "$module_dir")
            validate_module_no_resources "$module_name"
            echo
        fi
    done
    
    validate_examples_dev_settings
    echo
    validate_variable_constraints
    echo
    check_hardcoded_values
    
    show_validation_summary
}

# Parse command line arguments
case "${1:-}" in
    "modules")
        mkdir -p "$TEMP_DIR"
        for module_dir in "$TERRAFORM_MODULES_DIR"/*; do
            if [ -d "$module_dir" ]; then
                local module_name=$(basename "$module_dir")
                validate_module_no_resources "$module_name"
            fi
        done
        ;;
    "examples")
        validate_examples_dev_settings
        ;;
    "variables")
        validate_variable_constraints
        ;;
    "hardcoded")
        check_hardcoded_values
        ;;
    "")
        main
        ;;
    *)
        echo "Usage: $0 [modules|examples|variables|hardcoded]"
        echo "  modules    - Test that modules create no resources when disabled"
        echo "  examples   - Validate examples use development settings"
        echo "  variables  - Check variable constraints"
        echo "  hardcoded  - Check for hardcoded production values"
        echo "  (no args)  - Run full validation"
        exit 1
        ;;
esac