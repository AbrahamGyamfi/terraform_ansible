# ========================================
# EC2 Instance Module
# ========================================

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

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]

  monitoring = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3
              EOF

  tags = var.tags
}

resource "null_resource" "wait_for_instance" {
  depends_on = [aws_instance.web_server]

  provisioner "local-exec" {
    command = "sleep 30"
  }
}