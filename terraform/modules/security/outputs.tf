output "security_group_id" {
  description = "ID of the created security group"
  value       = aws_security_group.web_server.id
}