locals {
  name = "${var.project}-${var.env}-ec2"
  tags = {
    Project = var.project
    Env     = var.env
  }
}

# ──────────────────────────────
# Latest Amazon Linux 2023 AMI
# ──────────────────────────────
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ──────────────────────────────
# Security Group for EC2
# ──────────────────────────────
resource "aws_security_group" "instance" {
  name        = "${local.name}-sg"
  description = "Security group for ${local.name} instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# ──────────────────────────────
# EC2 Instance
# ──────────────────────────────
resource "aws_instance" "this" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.instance.id]
  iam_instance_profile   = var.iam_instance_profile
  key_name               = var.key_name

  # ✅ Fix: Ensure root volume >= snapshot (Amazon Linux 2023 → 30GB min)
  root_block_device {
    encrypted   = true
    volume_size = 30
  }

  tags = merge(local.tags, { Name = local.name })
}

