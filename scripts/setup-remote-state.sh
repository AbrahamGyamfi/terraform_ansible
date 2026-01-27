#!/bin/bash

# ========================================
# Automated S3 Backend Setup Script
# ========================================
# Creates S3 bucket and DynamoDB table, then configures Terraform backend

set -e

# Enable debug mode if DEBUG=1
if [[ "${DEBUG}" == "1" ]]; then
    set -x
fi

PROJECT_NAME="terraform-ansible"
REGION="us-east-1"
TABLE_NAME="${PROJECT_NAME}-locks"

# Check if bucket already exists, if not create with timestamp
EXISTING_BUCKET=$(aws s3 ls | grep "${PROJECT_NAME}-state-" | head -1 | awk '{print $3}')
if [ -n "$EXISTING_BUCKET" ]; then
    BUCKET_NAME="$EXISTING_BUCKET"
    echo "📦 Found existing S3 bucket: $BUCKET_NAME"
else
    BUCKET_NAME="${PROJECT_NAME}-state-$(date +%s)"
    echo "📦 Will create new S3 bucket: $BUCKET_NAME"
fi

echo "🚀 Setting up S3 remote state backend automatically..."

# Step 1: Create or use existing S3 bucket
echo "📦 Setting up S3 bucket: $BUCKET_NAME"
if aws s3api head-bucket --bucket $BUCKET_NAME 2>/dev/null; then
    echo "✅ S3 bucket $BUCKET_NAME already exists and is accessible"
else
    echo "🆕 Creating new S3 bucket: $BUCKET_NAME"
    aws s3 mb s3://$BUCKET_NAME --region $REGION
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket $BUCKET_NAME \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket $BUCKET_NAME \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket $BUCKET_NAME \
        --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    
    echo "✅ S3 bucket configured with versioning, encryption, and security settings"
fi

# Step 2: Create or use existing DynamoDB table
echo "🔒 Setting up DynamoDB table: $TABLE_NAME"
if aws dynamodb describe-table --table-name $TABLE_NAME --region $REGION &>/dev/null; then
    echo "✅ DynamoDB table $TABLE_NAME already exists and is active"
else
    echo "🆕 Creating new DynamoDB table: $TABLE_NAME"
    aws dynamodb create-table \
        --table-name $TABLE_NAME \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region $REGION
    
    # Wait for table to be active
    echo "⏳ Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name $TABLE_NAME --region $REGION
    echo "✅ DynamoDB table is now active"
fi

# Step 3: Update main.tf with backend configuration
echo "🔧 Configuring Terraform backend in main.tf..."

# Get the script directory and navigate to terraform directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

cd "$TERRAFORM_DIR"

# Add backend configuration to main.tf
sed -i.bak '/required_providers {/i\
\
  backend "s3" {\
    bucket         = "'$BUCKET_NAME'"\
    key            = "terraform.tfstate"\
    region         = "'$REGION'"\
    use_lockfile   = true\
    encrypt        = true\
  }\
' main.tf

# Step 4: Initialize Terraform with new backend
echo "🔄 Initializing Terraform with S3 backend..."
terraform init

echo "✅ S3 remote state setup complete!"
echo ""
echo "📋 Backend Configuration:"
echo "   Bucket: $BUCKET_NAME"
echo "   Key: terraform.tfstate"
echo "   Region: $REGION"
echo "   DynamoDB Table: $TABLE_NAME"
echo "   Encryption: Enabled"
echo ""
echo "🎉 Terraform is now configured with remote state and locking!"
echo "💡 You can now run: terraform plan/apply"