#!/bin/bash

# ========================================
# Cleanup Script
# ========================================
# This script destroys all AWS resources created by Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
EVIDENCE_DIR="$PROJECT_ROOT/evidence"

echo -e "${RED}========================================${NC}"
echo -e "${RED}  Infrastructure Cleanup${NC}"
echo -e "${RED}========================================${NC}\n"

echo -e "${YELLOW}This will destroy all AWS resources created by Terraform.${NC}"
echo -e "${YELLOW}This action cannot be undone.${NC}\n"

read -p "Are you sure you want to continue? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${BLUE}Cleanup cancelled.${NC}"
    exit 0
fi

# ========================================
# Terraform Destroy
# ========================================
echo -e "${YELLOW}Destroying infrastructure...${NC}\n"

cd "$TERRAFORM_DIR"

terraform destroy -auto-approve | tee "$EVIDENCE_DIR/DESTROY.txt"

echo -e "\n${GREEN}✓ Infrastructure destroyed${NC}\n"

# ========================================
# Cleanup Summary
# ========================================
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Cleanup Completed Successfully!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}The following resources have been removed:${NC}"
echo -e "  ✓ EC2 Instance"
echo -e "  ✓ Security Group"
echo -e "  ✓ AWS Key Pair"
echo -e "  ✓ SSH Keys (local files retained)\n"

echo -e "${BLUE}Evidence files:${NC}"
echo -e "  - ${GREEN}$EVIDENCE_DIR/DESTROY.txt${NC} (Terraform destroy output)\n"

echo -e "${YELLOW}Note: Local files (keys, inventory) are retained for reference.${NC}"
echo -e "${YELLOW}To completely clean up, manually delete the project directory.${NC}\n"
