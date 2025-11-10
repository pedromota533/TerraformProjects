#!/bin/bash

# Terraform Deployment Script
# Usage: ./terraform_deploy.sh <access_key> <secret_key> <environment> <target_deploy> <apply> <destroy>

# Check if all required arguments are provided
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <access_key> <secret_key> <environment> <target_deploy> <apply> <destroy>"
    echo ""
    echo "Arguments:"
    echo "  access_key     - AWS Access Key ID"
    echo "  secret_key     - AWS Secret Access Key"
    echo "  environment    - Environment (e.g., DEV, PROD, STAGING)"
    echo "  target_deploy  - Target deployment (e.g., aws, azure)"
    echo "  apply          - Apply changes? (yes/no)"
    echo "  destroy        - Destroy infrastructure? (yes/no)"
    exit 1
fi

# Assign arguments to variables
ACCESS_KEY="$1"
SECRET_KEY="$2"
ENVIRONMENT="$3"
TARGET_DEPLOY="$4"
APPLY="$5"
DESTROY="$6"


# Validate apply and destroy values
if [[ ! "$APPLY" =~ ^(yes|no)$ ]] || [[ ! "$DESTROY" =~ ^(yes|no)$ ]]; then
    echo "Error: 'apply' and 'destroy' must be either 'yes' or 'no'"
    exit 1
fi

# Execute destroy if requested
if [ "$DESTROY" = "yes" ]; then
    echo "Destroying infrastructure in terraform/${ENVIRONMENT}/"
    cd "terraform/${ENVIRONMENT}/" && terraform destroy
    cd ../../
    exit 0 
fi

# Execute terraform script
echo "Executing terraform script with environment: ${ENVIRONMENT}"

# Convert 'apply'/'no' to terraform action format
TERRAFORM_ACTION="plan"
if [ "$APPLY" = "yes" ]; then
    TERRAFORM_ACTION="apply"
fi

echo "Calling: ./scripts/terraform_execution.sh with params:"
echo "  ACCESS_KEY: ${ACCESS_KEY:0:10}..."
echo "  ENVIRONMENT: $ENVIRONMENT"
echo "  TARGET_DEPLOY: $TARGET_DEPLOY"
echo "  TERRAFORM_ACTION: $TERRAFORM_ACTION"
echo "  DESTROY: $DESTROY"

if [ ! -f "./scripts/terraform_execution.sh" ]; then
    echo "ERROR: terraform_execution.sh not found at ./scripts/terraform_execution.sh"
    exit 1
fi

./scripts/terraform_execution.sh "$ACCESS_KEY" "$SECRET_KEY" "$ENVIRONMENT" "$TARGET_DEPLOY" "$TERRAFORM_ACTION" "$DESTROY"

echo "Terraform execution completed"
