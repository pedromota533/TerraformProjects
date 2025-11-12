#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Change to automation-tools directory
cd "$(dirname "$0")/automation-tools" || exit 1

# Usage function
usage() {
    echo -e "${YELLOW}Usage: $0 [action]${NC}"
    echo ""
    echo "Actions:"
    echo "  init     - Initialize Terraform"
    echo "  plan     - Show execution plan"
    echo "  apply    - Apply infrastructure changes"
    echo "  destroy  - Destroy all resources"
    echo "  output   - Show outputs"
    echo "  clean    - Remove Terraform files"
    echo ""
    echo "Examples:"
    echo "  $0 apply"
    echo "  $0 destroy"
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

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Infrastructure applied successfully!${NC}"
            terraform output -json | jq > output.json
            echo -e "${GREEN}Outputs saved to output.json${NC}"
        fi
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
        echo -e "${YELLOW}Cleaning Terraform files...${NC}"
        rm -rf .terraform terraform.tfstate* .terraform.lock.hcl tfplan *.json 2>/dev/null
        echo -e "${GREEN}Cleanup complete!${NC}"
        ;;

    *)
        echo -e "${RED}Invalid action: $action${NC}"
        usage
        ;;
esac
