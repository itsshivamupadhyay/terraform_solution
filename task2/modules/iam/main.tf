locals {
  name = "${var.project}-${var.env}-ec2"
  tags = {
    Project = var.project
    Env     = var.env
  }
}

# IAM Assume Role Policy for EC2
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM Role
resource "aws_iam_role" "ec2" {
  name               = "${local.name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = local.tags
}

# IAM Role Policy: inline minimal example
resource "aws_iam_role_policy" "inline" {
  name = "${local.name}-inline"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ec2:Describe*"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach SSM core policy
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch Agent policy
resource "aws_iam_role_policy_attachment" "cwagent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name}-profile"
  role = aws_iam_role.ec2.name
  tags = local.tags
}

