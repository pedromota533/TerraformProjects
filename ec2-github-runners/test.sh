#!/bin/bash

# Script to test GitHub Runner Registration Token validity using API
# Usage: ./test.sh <github_token>

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -ne 1 ]; then
    echo -e "${RED}Error: GitHub token is required${NC}"
    echo ""
    echo "Usage: $0 <github_token>"
    echo ""
    echo "Example:"
    echo "  $0 ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABC"
    echo ""
    echo "Get a token from:"
    echo "  https://github.com/pedromota533/TerraformProjects/settings/actions/runners/new"
    exit 1
fi

GITHUB_TOKEN="$1"
REPO_OWNER="pedromota533"
REPO_NAME="TerraformProjects"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}GitHub Runner Token Validator (API)${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "Repository: $REPO_URL"
echo "Token: ${GITHUB_TOKEN:0:10}... (hidden)"
echo ""

echo -e "${BLUE}[1/3] Testing token format...${NC}"
echo ""

# Registration tokens are typically 40-50 characters
TOKEN_LENGTH=${#GITHUB_TOKEN}
if [ $TOKEN_LENGTH -lt 30 ]; then
    echo -e "${RED}✗ Token seems too short (${TOKEN_LENGTH} characters)${NC}"
    echo "Registration tokens are usually 40+ characters"
    exit 1
else
    echo -e "${GREEN}✓ Token format looks valid (${TOKEN_LENGTH} characters)${NC}"
fi

echo ""
echo -e "${BLUE}[2/3] Attempting minimal runner registration test...${NC}"
echo ""

# Note: GitHub does not provide an API to validate registration tokens
# The only way to test is to attempt actual registration
# We'll use a lightweight approach by downloading just the runner config script

# Create temporary directory
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

cd "$TEST_DIR"

# Download only the config script (much lighter than full runner)
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')

if [ -z "$RUNNER_VERSION" ]; then
    echo -e "${YELLOW}⚠ Could not fetch runner version, continuing with direct test...${NC}"
fi

# Download and extract runner
curl -sL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" | tar xz > /dev/null 2>&1

if [ ! -f "./config.sh" ]; then
    echo -e "${RED}✗ Failed to download runner tools${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Runner tools downloaded${NC}"

echo ""
echo -e "${BLUE}[3/3] Testing token with actual registration...${NC}"
echo ""

# Attempt configuration with the token
OUTPUT=$(./config.sh \
    --url "$REPO_URL" \
    --token "$GITHUB_TOKEN" \
    --name "token-validator-test" \
    --unattended 2>&1) || true

echo ""

# Check if token is valid based on config.sh output
if echo "$OUTPUT" | grep -q "Connected to GitHub"; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ TOKEN IS VALID!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "The token is working correctly."
    echo "You can now use it to configure your runners."
    echo ""

    # Remove the test configuration
    ./config.sh remove --token "$GITHUB_TOKEN" > /dev/null 2>&1 || true

    exit 0

elif echo "$OUTPUT" | grep -qi "HTTP response code: 404\|Not Found\|404 - Not Found"; then
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ TOKEN IS INVALID OR EXPIRED!${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Error: The token is not valid or has expired."
    echo ""
    echo "GitHub runner registration tokens expire after ~1 hour."
    echo ""
    echo "To get a new token:"
    echo "  1. Go to: https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/actions/runners/new"
    echo "  2. Copy the new token from the configuration command"
    echo "  3. Run this script again with the new token"
    echo ""
    exit 1

elif echo "$OUTPUT" | grep -qi "Forbidden\|403\|permission"; then
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ PERMISSION DENIED!${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Error: You don't have permission to register runners on this repository."
    echo ""
    echo "Make sure you have admin access to the repository."
    echo ""
    exit 1

elif echo "$OUTPUT" | grep -qi "must be unique\|already exists"; then
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}✓ TOKEN IS VALID (runner name exists)${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo "The token is valid!"
    echo "A runner with the test name already exists."
    echo ""
    exit 0

else
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}⚠ UNKNOWN RESULT${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo "Could not determine token validity."
    echo ""
    echo "Output:"
    echo "$OUTPUT"
    echo ""
    exit 1
fi