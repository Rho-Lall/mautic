terraform {
  backend "s3" {
    # Configuration provided via backend.hcl file
    # Run: terraform init -backend-config=backend.hcl
  }
}

# Provider configuration for application deployment
provider "aws" {
  region = "us-west-2"  # Application resources will be deployed here
}