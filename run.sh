#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

cd ./ec2-github-runners

# Function to display usage
usage() {
    echo -e "${RED}Error: GitHub token is required!${NC}"
    echo ""
    echo "Usage:"
    echo "  $0 <github_token> [action]"
    echo ""
    echo "Examples:"
    echo "  $0 ghp_xxxxxxxxxxxx              # Interactive mode with token"
    echo "  $0 ghp_xxxxxxxxxxxx init         # Run init"
    echo "  $0 ghp_xxxxxxxxxxxx plan         # Run plan"
    echo "  $0 ghp_xxxxxxxxxxxx apply        # Run apply"
    echo "  $0 ghp_xxxxxxxxxxxx full         # Run full workflow"
    echo ""
    echo "Actions: init, plan, apply, destroy, full, output, clean"
    exit 1
}

# Check if GitHub token is provided
if [ $# -eq 0 ]; then
    usage
fi

# Set the GitHub token as environment variable
export TF_VAR_github_token="$1"
shift  # Remove the first argument (token) from the list

# Check if action is provided
if [ $# -gt 0 ]; then
    # Command-line mode
    action=$1
    case $action in
        init) choice=1 ;;
        plan) choice=2 ;;
        apply) choice=3 ;;
        destroy) choice=4 ;;
        full) choice=5 ;;
        output) choice=6 ;;
        clean) choice=7 ;;
        *)
            echo -e "${RED}Invalid action: $action${NC}"
            echo "Usage: $0 <github_token> [init|plan|apply|destroy|full|output|clean]"
            exit 1
            ;;
    esac
else
    # Interactive mode
    echo -e "${GREEN}=== Terraform Runner Script ===${NC}"
    echo -e "${GREEN}GitHub Token: ${YELLOW}[CONFIGURED]${NC}"
    echo ""
    echo "Select an option:"
    echo "1) Init"
    echo "2) Plan"
    echo "3) Apply"
    echo "4) Destroy"
    echo "5) Full workflow (Init -> Plan -> Apply)"
    echo "6) Output JSON"
    echo "7) Clean (remove Terraform files)"
    echo "8) Exit"
    echo ""
    read -p "Enter your choice [1-8]: " choice
fi

case $choice in
    1)
        echo -e "${GREEN}Running terraform init...${NC}"
        terraform init
        ;;
    2)
        echo -e "${GREEN}Running terraform plan...${NC}"
        terraform plan
        ;;
    3)
        echo -e "${YELLOW}Running terraform apply...${NC}"
        terraform apply

        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}Saving infrastructure data...${NC}"
            terraform output -json | jq > infrastructure-data.json
            echo -e "${GREEN}Data saved to infrastructure-data.json${NC}"
        fi
        ;;
    4)
        echo -e "${RED}WARNING: This will destroy all resources!${NC}"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            terraform destroy
        else
            echo "Destroy cancelled."
        fi
        ;;
    5)
        echo -e "${GREEN}Running full workflow...${NC}"
        echo ""

        echo -e "${GREEN}Step 1: Initializing Terraform...${NC}"
        terraform init
        if [ $? -ne 0 ]; then
            echo -e "${RED}Init failed. Exiting.${NC}"
            exit 1
        fi
        echo ""

        echo -e "${GREEN}Step 2: Planning infrastructure...${NC}"
        terraform plan -out=tfplan
        if [ $? -ne 0 ]; then
            echo -e "${RED}Plan failed. Exiting.${NC}"
            exit 1
        fi
        echo ""

        echo -e "${YELLOW}Step 3: Applying plan...${NC}"
        read -p "Do you want to apply? (yes/no): " apply_confirm
        if [ "$apply_confirm" = "yes" ]; then
            terraform apply tfplan
            rm tfplan

            echo ""
            echo -e "${GREEN}=== Deployment Complete ===${NC}"
            echo ""
            echo "Getting outputs..."
            terraform output -json | jq > infrastructure-data.json
            echo -e "${GREEN}Outputs saved to output_info.json${NC}"
            echo ""
            echo "Public IPs:"
            terraform output -json | jq > infrastructure-data.json
        else
            echo "Apply cancelled."
            rm tfplan
        fi
        ;;
    6)
        echo -e "${GREEN}Exporting outputs to output_info.json...${NC}"
        terraform output -json > output_info.json
        echo ""
        echo "Runner Public IPs:"
        cat output_info.json | jq -r '.runner_public_ips.value[]'
        echo ""
        echo "Runner Private IPs:"
        cat output_info.json | jq -r '.runner_private_ips.value[]'
        ;;
    7)
        echo -e "${YELLOW}Cleaning Terraform files...${NC}"
        echo ""

        # Remove Terraform state files
        if [ -f "terraform.tfstate" ]; then
            rm terraform.tfstate
            echo "  Removed: terraform.tfstate"
        fi

        if [ -f "terraform.tfstate.backup" ]; then
            rm terraform.tfstate.backup
            echo "  Removed: terraform.tfstate.backup"
        fi

        # Remove Terraform directory
        if [ -d ".terraform" ]; then
            rm -rf .terraform
            echo "  Removed: .terraform/"
        fi

        if [ -f ".terraform.lock.hcl" ]; then
            rm .terraform.lock.hcl
            echo "  Removed: .terraform.lock.hcl"
        fi

        # Remove plan files
        if [ -f "tfplan" ]; then
            rm tfplan
            echo "  Removed: tfplan"
        fi

        # Remove output files
        if [ -f "infrastructure-data.json" ]; then
            rm infrastructure-data.json
            echo "  Removed: infrastructure-data.json"
        fi

        if [ -f "output_info.json" ]; then
            rm output_info.json
            echo "  Removed: output_info.json"
        fi

        echo ""
        echo -e "${GREEN}Cleanup complete!${NC}"
        ;;
    8)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac