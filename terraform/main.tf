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
# Data Sources
# ========================================

# Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# ========================================
# SSH Key Pair Generation
# ========================================

# Generate private key using TLS provider
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key to local file
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/../keys/${var.key_name}.pem"
  file_permission = "0400"
}

# Save public key to local file (optional, for reference)
resource "local_file" "public_key" {
  content         = tls_private_key.ssh_key.public_key_openssh
  filename        = "${path.module}/../keys/${var.key_name}.pub"
  file_permission = "0644"
}

# Register public key as AWS key pair
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh_key.public_key_openssh

  tags = {
    Name        = "${var.project_name}-key"
    Environment = var.environment
  }
}

# ========================================
# Security Group
# ========================================

resource "aws_security_group" "web_server" {
  name        = "${var.project_name}-sg"
  description = "Security group for Nginx web server - allows SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    description = "SSH from allowed CIDR blocks"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr
  }

  # HTTP access
  ingress {
    description = "HTTP from allowed CIDR blocks"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.http_allowed_cidr
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg"
    Environment = var.environment
  }
}

# ========================================
# EC2 Instance
# ========================================

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web_server.id]

  # Enable detailed monitoring (optional, but good practice)
  monitoring = true

  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  # User data to ensure Python is available for Ansible
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3
              EOF

  tags = {
    Name        = "${var.project_name}-server"
    Environment = var.environment
    Purpose     = "Nginx Web Server"
  }

  # Wait for instance to be ready before Ansible runs
  depends_on = [aws_security_group.web_server]
}

# ========================================
# Wait for instance to be ready
# ========================================

resource "null_resource" "wait_for_instance" {
  depends_on = [aws_instance.web_server]

  provisioner "local-exec" {
    command = "sleep 30"
  }
}
