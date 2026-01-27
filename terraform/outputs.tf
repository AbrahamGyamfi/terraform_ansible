# ========================================
# Output Definitions
# ========================================
# These outputs provide essential information for Ansible configuration
# and verification steps

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.ec2.public_dns
}

output "ssh_user" {
  description = "SSH username for connecting to the instance"
  value       = "ec2-user"
}

output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = module.ssh_keys.key_name
}

output "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  value       = module.ssh_keys.private_key_path
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.security.security_group_id
}

output "connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${module.ssh_keys.private_key_path} ec2-user@${module.ec2.public_ip}"
}

output "web_url" {
  description = "URL to access the web server"
  value       = "http://${module.ec2.public_ip}"
}

output "ansible_inventory_hint" {
  description = "Ansible inventory configuration hint"
  value       = <<-EOT
    Add to ansible/inventory.ini:
    [webservers]
    ${module.ec2.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=../keys/${var.key_name}.pem
  EOT
}
