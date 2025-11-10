#!/bin/bash
set -e
set -o pipefail

AWS_ACCESS_KEY_ID=$1
AWS_SECRET_ACCESS_KEY=$2
DEPLOY_TARGET=$3
DEPLOY_PLATFORM=$4
TERRAFORM_ACTION=$5
DESTROY_ACTION=$6

validate_required_params() {
    if [ -z "$AWS_ACCESS_KEY_ID" ]; then
        echo "ERROR: AWS_ACCESS_KEY_ID is not set"
        exit 1
    fi
    if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "ERROR: AWS_SECRET_ACCESS_KEY is not set"
        exit 1
    fi
    if [ -z "$DEPLOY_TARGET" ]; then
        echo "ERROR: DEPLOY_TARGET is not set"
        exit 1
    fi
    if [ -z "$DEPLOY_PLATFORM" ]; then
        echo "ERROR: DEPLOY_PLATFORM is not set"
        exit 1
    fi
    if [ -z "$TERRAFORM_ACTION" ]; then
        echo "ERROR: TERRAFORM_ACTION is not set"
        exit 1
    fi
    if [ -z "$DESTROY_ACTION" ]; then
        echo "ERROR: DESTROY_ACTION is not set"
        exit 1
    fi
}

validate_terraform_action() {
    if [[ ! "$TERRAFORM_ACTION" =~ ^(apply|plan)$ ]]; then
        echo "ERROR: TERRAFORM_ACTION must be 'apply' or 'plan'"
        exit 1
    fi
}

validate_destroy_action() {
    if [[ ! "$DESTROY_ACTION" =~ ^(yes|no)$ ]]; then
        echo "ERROR: DESTROY_ACTION must be 'yes' or 'no'"
        exit 1
    fi
}

setup_aws_environment() {
    export AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY
    export AWS_DEFAULT_REGION="${AWS_REGION:-eu-west-1}"
    echo "Terraform Execution Details:"
    echo "  Platform: $DEPLOY_PLATFORM"
    echo "  Target: $DEPLOY_TARGET"
    echo "  AWS Region: $AWS_DEFAULT_REGION"
}

validate_terraform_directory() {
    local terraform_dir=$1
    
    if [ ! -d "$terraform_dir" ]; then
        echo "ERROR: Directory $terraform_dir does not exist"
        exit 1
    fi
    
    if [ ! -f "$terraform_dir/main.tf" ]; then
        echo "ERROR: main.tf not found in $terraform_dir"
        exit 1
    fi
}

run_terraform_destroy() {
    echo "Running terraform destroy..."
    terraform destroy -auto-approve
}

run_terraform_init() {
    echo "Running terraform init..."
    if ! terraform init; then
        echo "ERROR: terraform init failed"
        exit 1
    fi
}

run_terraform_validate() {
    echo "Running terraform validate..."
    if ! terraform validate; then
        echo "ERROR: terraform validate failed"
        exit 1
    fi
}

run_terraform_plan() {
    echo "Running terraform plan..."
    if ! terraform plan -out=tfplan; then
        echo "ERROR: terraform plan failed"
        exit 1
    fi
}

run_terraform_apply() {
    echo "Running terraform apply..."
    if ! terraform apply -auto-approve tfplan; then
        echo "ERROR: terraform apply failed"
        exit 1
    fi
    echo "OK: Terraform apply completed successfully"
}

main() {
    validate_required_params
    validate_terraform_action
    validate_destroy_action
    setup_aws_environment
    
    TERRAFORM_DIR="terraform/${DEPLOY_TARGET}"
    validate_terraform_directory "$TERRAFORM_DIR"
    
    echo "Working directory: $TERRAFORM_DIR"
    cd "$TERRAFORM_DIR"
    
    if [ "$DESTROY_ACTION" == "yes" ]; then
        run_terraform_destroy
    fi
    
    run_terraform_init
    run_terraform_validate
    run_terraform_plan
    
    if [ "$TERRAFORM_ACTION" == "apply" ]; then
        run_terraform_apply
    else
        echo "OK: Terraform plan completed successfully (NOT APPLIED)"
    fi
}

main
