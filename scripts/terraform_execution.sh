#!/bin/bash

set -e
set -o pipefail




if [ -z "$DEPLOY_PLATFORM" ]; then
    echo "ERROR: DEPLOY_PLATFORM is not set"
    exit 1
fi

if [ -z "$DEPLOY_TARGET" ]; then
    echo "ERROR: DEPLOY_TARGET is not set"
    exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "ERROR: AWS_ACCESS_KEY_ID is not set"
    exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "ERROR: AWS_SECRET_ACCESS_KEY is not set"
    exit 1
fi

# Set AWS credentials
export AWS_DEFAULT_REGION="${AWS_REGION:-eu-west-1}"

echo "Terraform Execution Details:"
echo "  Platform: $DEPLOY_PLATFORM"
echo "  Target: $DEPLOY_TARGET"
echo "  AWS Region: $AWS_DEFAULT_REGION"

TERRAFORM_DIR="terraform/${DEPLOY_TARGET}"

if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "ERROR: Directory $TERRAFORM_DIR does not exist"
    exit 1
fi

if [ ! -f "$TERRAFORM_DIR/main.tf" ]; then
    echo "ERROR: main.tf not found in $TERRAFORM_DIR"
    exit 1
fi

echo "Working directory: $TERRAFORM_DIR"

cd "$TERRAFORM_DIR"

echo "Running terraform init..."
if ! terraform init; then
    echo "ERROR: terraform init failed"
    exit 1
fi

echo "Running terraform validate..."
if ! terraform validate; then
    echo "ERROR: terraform validate failed"
    exit 1
fi

echo "Running terraform plan..."
if ! terraform plan -out=tfplan; then
    echo "ERROR: terraform plan failed"
    exit 1
fi

if [ "${TERRAFORM_ACTION}" == "apply" ]; then
    echo "Running terraform apply..."
    if ! terraform apply -auto-approve tfplan; then
        echo "ERROR: terraform apply failed"
        exit 1
    fi
    echo "OK: Terraform apply completed successfully"
else
    echo "OK: Terraform plan completed successfully"
fi
