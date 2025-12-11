#!/bin/bash

# Terraform Module Syntax-Only Validation Script
# This script validates Terraform module syntax without executing plans
# Focuses on Requirements 3.1 and 5.1 validation

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_MODULES_DIR="$MODULE_ROOT/terraform/modules"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

add_error() {
    ((VALIDATION_ERRORS++))
    log_error "$1"
}

add_warning() {
    ((VALIDATION_WARNINGS++))
    log_warning "$1"
}

# Function to validate module syntax using terraform validate
validate_module_syntax() {
    local module_name="$1"
    local module_dir="$TERRAFORM_MODULES_DIR/$module_name"
    
    if [ ! -d "$module_dir" ]; then
        add_error "Module directory not found: $module_name"
        return 1
    fi
    
    log_info "Validating syntax for module: $module_name"
    
    cd "$module_dir"
    
    # Check if terraform files exist
    if ! ls *.tf &> /dev/null; then
        add_error "Module $module_name: No Terraform files found"
        return 1
    fi
    
    # Initialize terraform (this validates syntax)
    if ! terraform init -backend=false -no-color &> init.log; then
        add_error "Module $module_name: Terraform init failed"
        echo "Init errors:"
        cat init.log | head -10
        return 1
    fi
    
    # Validate syntax
    if ! terraform validate -no-color &> validate.log; then
        add_error "Module $module_name: Terraform validate failed"
        echo "Validation errors:"
        cat validate.log
        return 1
    fi
    
    log_success "Module $module_name: Syntax validation passed ✓"
    return 0
}

# Function to check required files
check_module_structure() {
    local module_name="$1"
    local module_dir="$TERRAFORM_MODULES_DIR/$module_name"
    
    log_info "  Checking file structure..."
    
    local required_files=("main.tf" "variables.tf" "outputs.tf")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$module_dir/$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        log_success "  All required files present ✓"
    else
        add_warning "  Missing files: ${missing_files[*]}"
    fi
    
    # Check for README.md
    if [ -f "$module_dir/README.md" ]; then
        log_success "  Documentation present ✓"
    else
        add_warning "  Missing README.md documentation"
    fi
}

# Function to check variable definitions
check_variable_definitions() {
    local module_name="$1"
    local module_dir="$TERRAFORM_MODULES_DIR/$module_name"
    
    log_info "  Checking variable definitions..."
    
    # Check for required security variables
    local required_vars=("create_resources" "environment" "project_name" "tags")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "variable.*\"$var\"" "$module_dir/variables.tf"; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -eq 0 ]; then
        log_success "  All required security variables present ✓"
    else
        add_warning "  Missing security variables: ${missing_vars[*]}"
    fi
    
    # Check for variable validation
    local vars_with_validation=$(grep -c "validation {" "$module_dir/variables.tf" || true)
    if [ "$vars_with_validation" -gt 0 ]; then
        log_success "  Variable validation rules present ($vars_with_validation rules) ✓"
    else
        add_warning "  No variable validation rules found"
    fi
}

# Function to check create_resources pattern
check_create_resources_pattern() {
    local module_name="$1"
    local module_dir="$TERRAFORM_MODULES_DIR/$module_name"
    
    log_info "  Checking create_resources pattern..."
    
    # Count resources and those with create_resources pattern
    local total_resources=$(grep -c "^resource " "$module_dir/main.tf" || true)
    local resources_with_count=$(grep -c "count.*var\.create_resources" "$module_dir/main.tf" || true)
    
    if [ "$total_resources" -eq 0 ]; then
        add_warning "  No resources found in main.tf"
        return
    fi
    
    if [ "$resources_with_count" -eq "$total_resources" ]; then
        log_success "  All $total_resources resources implement create_resources pattern ✓"
    elif [ "$resources_with_count" -gt 0 ]; then
        add_warning "  Only $resources_with_count/$total_resources resources implement create_resources pattern"
    else
        add_warning "  No resources implement create_resources pattern (0/$total_resources)"
        log_warning "    Resources should use 'count = var.create_resources ? 1 : 0' pattern"
    fi
}

# Function to check for hardcoded values
check_hardcoded_values() {
    local module_name="$1"
    local module_dir="$TERRAFORM_MODULES_DIR/$module_name"
    
    log_info "  Checking for hardcoded values..."
    
    local forbidden_patterns=(
        "prod"
        "production"
        "staging"
        "123456789012"
        "arn:aws:iam::[0-9]{12}:"
    )
    
    local violations=0
    
    for pattern in "${forbidden_patterns[@]}"; do
        if grep -qE "$pattern" "$module_dir"/*.tf 2>/dev/null; then
            ((violations++))
            add_warning "  Hardcoded value '$pattern' found in module files"
        fi
    done
    
    if [ $violations -eq 0 ]; then
        log_success "  No hardcoded production values found ✓"
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
    
    # Check variable definitions
    check_variable_definitions "$module_name"
    
    # Check create_resources pattern
    check_create_resources_pattern "$module_name"
    
    # Check for hardcoded values
    check_hardcoded_values "$module_name"
    
    # Validate syntax
    if validate_module_syntax "$module_name"; then
        log_success "Module $module_name: Syntax validation completed ✓"
    else
        log_error "Module $module_name: Syntax validation failed ✗"
        return 1
    fi
    
    return 0
}

# Function to show validation summary
show_validation_summary() {
    echo
    echo "========================================"
    log_info "Module Syntax Validation Summary"
    echo "========================================"
    echo "Modules tested: $MODULES_TESTED"
    echo "Errors: $VALIDATION_ERRORS"
    echo "Warnings: $VALIDATION_WARNINGS"
    echo
    
    if [ $VALIDATION_ERRORS -eq 0 ] && [ $VALIDATION_WARNINGS -eq 0 ]; then
        log_success "🎉 All modules passed syntax validation!"
        log_success "✓ All modules have valid Terraform syntax"
        log_success "✓ All modules have proper file structure"
        log_success "✓ Variable validation is implemented"
        echo
        log_success "Modules are syntactically correct and ready for testing."
    elif [ $VALIDATION_ERRORS -eq 0 ]; then
        log_warning "⚠️  Syntax validation completed with warnings"
        log_warning "All critical validations passed, but improvements recommended"
        echo
        log_success "Modules are syntactically correct but could be improved."
    else
        log_error "❌ Syntax validation failed with critical errors"
        log_error "Fix all syntax errors before proceeding"
        echo
        log_error "Modules have syntax issues that must be resolved."
        exit 1
    fi
}

# Main validation function
main() {
    log_info "Starting Terraform module syntax validation..."
    log_info "This validates module syntax and structure without AWS API calls"
    echo
    
    # Check prerequisites
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    local terraform_version=$(terraform version -json 2>/dev/null | grep '"version"' | cut -d'"' -f4 || echo "unknown")
    log_info "Using Terraform version: $terraform_version"
    
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