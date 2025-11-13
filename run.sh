#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Change to automation-tools directory
cd "$(dirname "$0")/automation-tools" || exit 1

# Function to check if GitHub token is set
check_github_token() {
    if [ -z "$TF_VAR_github_token" ]; then
        echo -e "${RED}ERROR: TF_VAR_github_token environment variable is not set!${NC}"
        echo -e "${YELLOW}Please set it with: export TF_VAR_github_token='your-token'${NC}"
        exit 1
    fi
}

# Function to check if command succeeded
check_status() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: $1 failed!${NC}"
        exit 1
    fi
}

# Usage function
usage() {
    echo -e "${YELLOW}Usage: $0 [action]${NC}"
    echo ""
    echo "Actions:"
    echo "  init     - Initialize Terraform"
    echo "  plan     - Show execution plan"
    echo "  apply    - Apply infrastructure changes"
    echo "  full     - Run init, plan, and apply in sequence"
    echo "  destroy  - Destroy all resources"
    echo "  output   - Show outputs"
    echo "  clean    - Remove Terraform files (prompts for confirmation)"
    echo ""
    echo "Examples:"
    echo "  $0 full      # Complete deployment workflow"
    echo "  $0 apply"
    echo "  $0 destroy"
    echo ""
    echo "Note: Set TF_VAR_github_token environment variable before running apply or full"
    exit 1
}

# Check argument
if [ $# -eq 0 ]; then
    usage
fi

action=$1

case $action in
    init)
        echo -e "${GREEN}Initializing Terraform...${NC}"
        terraform init
        ;;

    plan)
        echo -e "${GREEN}Running terraform plan...${NC}"
        terraform plan
        ;;

    apply)
        echo -e "${YELLOW}Applying infrastructure...${NC}"
        terraform apply -auto-approve
        check_status "Terraform apply"

        echo -e "${GREEN}Infrastructure applied successfully!${NC}"
        terraform output -json | jq > output.json 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Outputs saved to output.json${NC}"
        fi
        ;;

    full)
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}Starting Full Deployment Workflow${NC}"
        echo -e "${BLUE}========================================${NC}"
        echo ""

        # Step 1: Init
        echo -e "${GREEN}[1/3] Initializing Terraform...${NC}"
        terraform init
        check_status "Terraform init"
        echo -e "${GREEN}✓ Init completed${NC}"
        echo ""

        # Step 2: Plan
        echo -e "${GREEN}[2/3] Running terraform plan...${NC}"
        terraform plan -out=tfplan
        check_status "Terraform plan"
        echo -e "${GREEN}✓ Plan completed${NC}"
        echo ""

        # Step 3: Apply
        echo -e "${YELLOW}[3/3] Applying infrastructure...${NC}"
        read -p "Continue with apply? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo -e "${YELLOW}Apply cancelled.${NC}"
            rm -f tfplan
            exit 0
        fi

        terraform apply tfplan
        check_status "Terraform apply"
        rm -f tfplan

        echo ""
        echo -e "${GREEN}✓ Apply completed${NC}"
        echo -e "${GREEN}Infrastructure deployed successfully!${NC}"

        # Save outputs
        terraform output -json | jq > output.json 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Outputs saved to output.json${NC}"
        fi

        echo ""
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}Deployment Complete!${NC}"
        echo -e "${BLUE}========================================${NC}"
        terraform output
        ;;

    destroy)
        echo -e "${RED}WARNING: This will destroy all resources!${NC}"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            terraform destroy -auto-approve
            echo -e "${GREEN}Resources destroyed.${NC}"
        else
            echo "Destroy cancelled."
        fi
        ;;

    output)
        echo -e "${GREEN}Terraform Outputs:${NC}"
        terraform output
        ;;

    clean)
        echo -e "${RED}WARNING: This will remove all Terraform files and state!${NC}"
        echo -e "${YELLOW}Files to be removed:${NC}"
        echo "  - .terraform/"
        echo "  - terraform.tfstate*"
        echo "  - .terraform.lock.hcl"
        echo "  - tfplan"
        echo "  - output.json"
        echo ""
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            echo -e "${YELLOW}Cleaning Terraform files...${NC}"
            rm -rf .terraform terraform.tfstate* .terraform.lock.hcl tfplan output.json 2>/dev/null
            echo -e "${GREEN}Cleanup complete!${NC}"
        else
            echo -e "${YELLOW}Cleanup cancelled.${NC}"
        fi
        ;;

    *)
        echo -e "${RED}Invalid action: $action${NC}"
        usage
        ;;
esac
