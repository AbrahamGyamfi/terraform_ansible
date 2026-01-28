# ========================================
# Variable Definitions
# ========================================
# This file contains all input variables for the Terraform configuration
# Follow best practices: provide descriptions, types, and defaults where appropriate

variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  type        = string
  default     = "eu-west-1"
}

variable "availability_zone" {
  description = "Availability zone for subnet placement"
  type        = string
  default     = "eu-west-1a"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "nginx-deployment"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed to SSH into the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Restrict this in production!
}

variable "http_allowed_cidr" {
  description = "CIDR blocks allowed to access HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Name for the SSH key pair"
  type        = string
  default     = "terraform-ansible-key"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "Nginx-Ansible-Deployment"
  }
}
