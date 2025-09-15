locals {
  name = "${var.project}-${var.env}-sg"
  tags = {
    Project = var.project
    Env     = var.env
  }
}

# Restrictive security group: no inbound, only HTTPS/HTTP egress
resource "aws_security_group" "instance" {
  name        = local.name
  description = "Restrictive SG for private EC2"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  # Allow outbound HTTP
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound HTTPS
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.name })
}

