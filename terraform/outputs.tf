# ========================================
# Output Definitions
# ========================================
# These outputs provide essential information for Ansible configuration
# and verification steps

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web_server.private_ip
}

output "ssh_user" {
  description = "SSH username for connecting to the instance"
  value       = "ec2-user"
}

output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.deployer.key_name
}

output "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  value       = local_file.private_key.filename
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web_server.id
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.web_server.public_ip}"
}

output "web_url" {
  description = "URL to access the web server"
  value       = "http://${aws_instance.web_server.public_ip}"
}

output "ansible_inventory_hint" {
  description = "Ansible inventory configuration hint"
  value       = <<-EOT
    Add to ansible/inventory.ini:
    [webservers]
    ${aws_instance.web_server.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=../keys/${var.key_name}.pem
  EOT
}
