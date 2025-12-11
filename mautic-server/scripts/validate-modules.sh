#!/bin/bash

# Terraform Module Independent Validation Script
# This script validates each Terraform module independently to ensure:
# 1. All modules pass terraform validate
# 2. No actual resources would be created in development mode
# 3. Variable validation and error handling work correctly

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_MODULES_DIR="$MODULE_ROOT/terraform/modules"
TEMP_DIR="/tmp/mautic-module-validation-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validation results
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0
MODULES_TESTED=0

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

# Function to create minimal test configuration for a module
create_minimal_test_config() {
    local module_name="$1"
    local test_dir="$2"
    
    mkdir -p "$test_dir"
    
    # Create main.tf with minimal required configuration
    cat > "$test_dir/main.tf" << EOF
# Minimal test configuration for $module_name module validation
# This configuration is designed to test module syntax and validation only

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS provider for validation testing
provider "aws" {
  region = "us-east-1"
  
  # Skip all AWS API calls for validation-only testing
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  
  # Use access keys that will prevent any real AWS calls
  access_key = "mock_access_key"
  secret_key = "mock_secret_key"
}

# Module under test with minimal required variables
module "$module_name" {
  source = "MODULE_ROOT_PLACEHOLDER/terraform/modules/$module_name"
  
  # Required security safeguards
  create_resources = false
  environment      = "dev"
  project_name     = "test-validation"
  
  # Common tags
  tags = {
    Environment = "dev"
    Testing     = "validation-only"
    Module      = "$module_name"
  }
EOF

    # Add module-specific required variables based on module type
    case "$module_name" in
        "database")
            cat >> "$test_dir/main.tf" << 'EOF'
  
  # Database-specific required variables
  subnet_ids         = ["subnet-12345678", "subnet-87654321"]
  security_group_ids = ["sg-12345678"]
  master_password    = "test-password-123"
EOF
            ;;
        "networking")
            # Networking module typically doesn't need additional variables
            ;;
        "ecs-cluster")
            cat >> "$test_dir/main.tf" << 'EOF'
  
  # ECS-specific required variables
  subnet_ids         = ["subnet-12345678", "subnet-87654321"]
  security_group_ids = ["sg-12345678"]
EOF
            ;;
        "load-balancer")
            cat >> "$test_dir/main.tf" << 'EOF'
  
  # Load balancer-specific required variables
  vpc_id             = "vpc-12345678"
  subnet_ids         = ["subnet-12345678", "subnet-87654321"]
  security_group_ids = ["sg-12345678"]
EOF
            ;;
        "monitoring")
            # Monitoring module typically doesn't need additional variables
            ;;
        "mautic-service")
            cat >> "$test_dir/main.tf" << 'EOF'
  
  # Mautic service-specific required variables
  vpc_id                = "vpc-12345678"
  subnet_ids           = ["subnet-12345678", "subnet-87654321"]
  security_group_ids   = ["sg-12345678"]
  target_group_arn     = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/1234567890123456"
  cluster_id           = "test-cluster"
  database_endpoint    = "test-db.cluster-xyz.us-east-1.rds.amazonaws.com"
  database_name        = "mautic"
  database_username    = "mautic_admin"
  database_password    = "test-password-123"
EOF
            ;;
    esac
    
    cat >> "$test_dir/main.tf" << 'EOF'
}

# Test outputs to verify module interface
output "module_outputs" {
  description = "All outputs from the module for validation"
  value       = module.MODULE_NAME
  sensitive   = true
}
EOF

    # Replace placeholders
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/MODULE_NAME/$module_name/g" "$test_dir/main.tf"
        sed -i '' "s|MODULE_ROOT_PLACEHOLDER|$MODULE_ROOT|g" "$test_dir/main.tf"
    else
        sed -i "s/MODULE_NAME/$module_name/g" "$test_dir/main.tf"
        sed -i "s|MODULE_ROOT_PLACEHOLDER|$MODULE_ROOT|g" "$test_dir/main.tf"
    fi
}

# Function to validate module syntax and configuration
validate_module_syntax() {
    local module_name="$1"
    local module_dir="$TERRAFORM_MODULES_DIR/$module_name"
    
    if [ ! -d "$module_dir" ]; then
        add_error "Module directory not found: $module_name"
        return 1
    fi
    
    log_info "Validating module syntax: $module_name"
    
    # Create test directory
    local test_dir="$TEMP_DIR/$module_name"
    create_minimal_test_config "$module_name" "$test_dir"
    
    cd "$test_dir"
    
    # Initialize Terraform
    log_info "  Initializing Terraform for $module_name..."
    if ! terraform init -no-color &> init.log; then
        add_error "Module $module_name: Terraform init failed"
        echo "Init log:"
        cat init.log | head -20
        return 1
    fi
    
    # Validate configuration
    log_info "  Running terraform validate for $module_name..."
    if ! terraform validate -no-color &> validate.log; then
        add_error "Module $module_name: Terraform validate failed"
        echo "Validation errors:"
        cat validate.log
        return 1
    fi
    
    log_success "Module $module_name: Syntax validation passed ✓"
    return 0
}

# Function to verify no resources would be created
verify_no_resource_creation() {
    local module_name="$1"
    local test_dir="$TEMP_DIR/$module_name"
    
    cd "$test_dir"
    
    log_info "  Verifying resource creation behavior for $module_name..."
    
    # Plan with create_resources = false (default)
    if ! terraform plan -no-color -out=plan.out &> plan.log; then
        add_error "Module $module_name: Terraform plan failed"
        echo "Plan errors:"
        cat plan.log | head -20
        return 1
    fi
    
    # Check that no resources will be created
    local resources_to_create=$(terraform show -no-color plan.out | grep -c "will be created" || true)
    local resources_to_change=$(terraform show -no-color plan.out | grep -c "will be updated" || true)
    local resources_to_destroy=$(terraform show -no-color plan.out | grep -c "will be destroyed" || true)
    
    if [ "$resources_to_create" -eq 0 ] && [ "$resources_to_change" -eq 0 ] && [ "$resources_to_destroy" -eq 0 ]; then
        log_success "Module $module_name: No resources will be created/modified/destroyed ✓"
        return 0
    else
        # Check if module implements create_resources pattern
        if grep -q "count.*var\.create_resources" "$MODULE_ROOT/terraform/modules/$module_name/main.tf"; then
            add_error "Module $module_name: Would create $resources_to_create resources despite create_resources = false"
            echo "This indicates a bug in the create_resources implementation"
        else
            add_warning "Module $module_name: Does not implement create_resources safeguard pattern"
            log_warning "  Would create $resources_to_create, change $resources_to_change, destroy $resources_to_destroy resources"
            log_warning "  Module needs to implement 'count = var.create_resources ? 1 : 0' pattern"
        fi
        
        echo "Plan summary (first 20 lines):"
        terraform show -no-color plan.out | head -20
        return 1
    fi
}

# Function to test variable validation
test_variable_validation() {
    local module_name="$1"
    local test_dir="$TEMP_DIR/$module_name"
    
    log_info "  Testing variable validation for $module_name..."
    
    # Create test configuration with invalid values
    local invalid_test_dir="$test_dir-invalid"
    mkdir -p "$invalid_test_dir"
    
    # Copy base configuration
    cp "$test_dir/main.tf" "$invalid_test_dir/"
    
    cd "$invalid_test_dir"
    
    # Test invalid environment value
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/environment      = "dev"/environment      = "invalid"/' main.tf
    else
        sed -i 's/environment      = "dev"/environment      = "invalid"/' main.tf
    fi
    
    terraform init -no-color &> /dev/null || true
    
    if terraform validate -no-color &> validate_invalid.log; then
        add_warning "Module $module_name: Should reject invalid environment value"
    else
        if grep -q "Environment must be" validate_invalid.log; then
            log_success "Module $module_name: Correctly rejects invalid environment ✓"
        else
            add_warning "Module $module_name: Validation error message unclear"
        fi
    fi
    
    # Test invalid project name
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/environment      = "invalid"/environment      = "dev"/' main.tf
        sed -i '' 's/project_name     = "test-validation"/project_name     = "Invalid_Name!"/' main.tf
    else
        sed -i 's/environment      = "invalid"/environment      = "dev"/' main.tf
        sed -i 's/project_name     = "test-validation"/project_name     = "Invalid_Name!"/' main.tf
    fi
    
    if terraform validate -no-color &> validate_project.log; then
        add_warning "Module $module_name: Should reject invalid project name"
    else
        if grep -q "must contain only lowercase" validate_project.log; then
            log_success "Module $module_name: Correctly rejects invalid project name ✓"
        else
            add_warning "Module $module_name: Project name validation unclear"
        fi
    fi
    
    return 0
}

# Function to check module file structure
check_module_structure() {
    local module_name="$1"
    local module_dir="$TERRAFORM_MODULES_DIR/$module_name"
    
    log_info "  Checking file structure for $module_name..."
    
    local required_files=("main.tf" "variables.tf" "outputs.tf")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$module_dir/$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        log_success "Module $module_name: All required files present ✓"
    else
        add_warning "Module $module_name: Missing files: ${missing_files[*]}"
    fi
    
    # Check for README.md
    if [ -f "$module_dir/README.md" ]; then
        log_success "Module $module_name: Documentation present ✓"
    else
        add_warning "Module $module_name: Missing README.md documentation"
    fi
}

# Function to check create_resources pattern implementation
check_create_resources_pattern() {
    local module_name="$1"
    local module_dir="$TERRAFORM_MODULES_DIR/$module_name"
    
    log_info "  Checking create_resources pattern for $module_name..."
    
    # Check if variables.tf has create_resources variable
    if grep -q 'variable.*"create_resources"' "$module_dir/variables.tf"; then
        log_success "Module $module_name: Has create_resources variable ✓"
    else
        add_warning "Module $module_name: Missing create_resources variable in variables.tf"
        return 1
    fi
    
    # Check if main.tf uses create_resources in resource count
    local resources_with_count=$(grep -c "count.*var\.create_resources" "$module_dir/main.tf" || true)
    local total_resources=$(grep -c "^resource " "$module_dir/main.tf" || true)
    
    if [ "$resources_with_count" -gt 0 ]; then
        if [ "$resources_with_count" -eq "$total_resources" ]; then
            log_success "Module $module_name: All resources implement create_resources pattern ✓"
        else
            add_warning "Module $module_name: Only $resources_with_count/$total_resources resources implement create_resources pattern"
        fi
    else
        add_warning "Module $module_name: No resources implement create_resources pattern"
        log_warning "  Resources should use 'count = var.create_resources ? 1 : 0' pattern"
    fi
}

# Function to validate individual module
validate_individual_module() {
    local module_name="$1"
    
    echo
    log_info "=== Validating Module: $module_name ==="
    
    ((MODULES_TESTED++))
    
    # Check module structure
    check_module_structure "$module_name"
    
    # Check create_resources pattern
    check_create_resources_pattern "$module_name"
    
    # Validate syntax
    if ! validate_module_syntax "$module_name"; then
        return 1
    fi
    
    # Verify no resource creation (don't fail on this, just report)
    verify_no_resource_creation "$module_name" || true
    
    # Test variable validation
    test_variable_validation "$module_name"
    
    log_success "Module $module_name: Validation completed"
    return 0
}

# Function to show validation summary
show_validation_summary() {
    echo
    echo "========================================"
    log_info "Module Validation Summary"
    echo "========================================"
    echo "Modules tested: $MODULES_TESTED"
    echo "Errors: $VALIDATION_ERRORS"
    echo "Warnings: $VALIDATION_WARNINGS"
    echo
    
    if [ $VALIDATION_ERRORS -eq 0 ] && [ $VALIDATION_WARNINGS -eq 0 ]; then
        log_success "🎉 All modules passed validation!"
        log_success "✓ All modules have valid Terraform syntax"
        log_success "✓ No resources will be created in development mode"
        log_success "✓ Variable validation is working correctly"
        echo
        log_success "Modules are ready for independent use and public release."
    elif [ $VALIDATION_ERRORS -eq 0 ]; then
        log_warning "⚠️  Validation completed with warnings"
        log_warning "All critical validations passed, but some improvements recommended"
        echo
        log_success "Modules are functional but could be improved."
    else
        log_error "❌ Validation failed with critical errors"
        log_error "Fix all errors before using modules or public release"
        echo
        log_error "Modules are not ready for use."
        exit 1
    fi
}

# Main validation function
main() {
    log_info "Starting independent Terraform module validation..."
    log_info "This will validate each module can be used independently"
    echo
    
    # Check prerequisites
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed or not in PATH"
        log_error "Please install Terraform to run validation"
        exit 1
    fi
    
    local terraform_version=$(terraform version -json | grep '"version"' | cut -d'"' -f4)
    log_info "Using Terraform version: $terraform_version"
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Get list of modules
    local modules=()
    for module_dir in "$TERRAFORM_MODULES_DIR"/*; do
        if [ -d "$module_dir" ]; then
            modules+=($(basename "$module_dir"))
        fi
    done
    
    if [ ${#modules[@]} -eq 0 ]; then
        log_error "No modules found in $TERRAFORM_MODULES_DIR"
        exit 1
    fi
    
    log_info "Found ${#modules[@]} modules to validate: ${modules[*]}"
    
    # Validate each module
    for module_name in "${modules[@]}"; do
        validate_individual_module "$module_name"
    done
    
    show_validation_summary
}

# Parse command line arguments
case "${1:-}" in
    "")
        main
        ;;
    *)
        if [ -d "$TERRAFORM_MODULES_DIR/$1" ]; then
            # Validate specific module
            mkdir -p "$TEMP_DIR"
            validate_individual_module "$1"
            show_validation_summary
        else
            echo "Usage: $0 [module_name]"
            echo
            echo "Available modules:"
            for module_dir in "$TERRAFORM_MODULES_DIR"/*; do
                if [ -d "$module_dir" ]; then
                    echo "  - $(basename "$module_dir")"
                fi
            done
            exit 1
        fi
        ;;
esac