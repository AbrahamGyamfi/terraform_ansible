# ========================================
# Main Terraform Configuration
# ========================================
# This file contains the core infrastructure definitions
# Provisions EC2 instance with security groups and SSH key pair

# ========================================
# Provider Configuration
# ========================================
terraform {
  required_version = ">= 1.0"


  backend "s3" {
    bucket         = "terraform-ansible-state-1769520529"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}

# ========================================
# Module Calls
# ========================================

# SSH Key Module
module "ssh_keys" {
  source = "./modules/keys"

  key_name  = var.key_name
  keys_path = "${path.module}/../keys"
  tags = {
    Name        = "${var.project_name}-key"
    Environment = var.environment
  }
}

# Security Group Module
module "security" {
  source = "./modules/security"

  project_name      = var.project_name
  ssh_allowed_cidr  = var.ssh_allowed_cidr
  http_allowed_cidr = var.http_allowed_cidr
  tags = {
    Name        = "${var.project_name}-sg"
    Environment = var.environment
  }
}

# EC2 Instance Module
module "ec2" {
  source = "./modules/ec2"

  project_name      = var.project_name
  instance_type     = var.instance_type
  key_name          = module.ssh_keys.key_name
  security_group_id = module.security.security_group_id
  tags = {
    Name        = "${var.project_name}-server"
    Environment = var.environment
    Purpose     = "Nginx Web Server"
  }
}
