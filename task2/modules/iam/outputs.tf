output "role_name" {
  description = "IAM role name for EC2"
  value       = aws_iam_role.ec2.name
}

output "instance_profile" {
  description = "IAM instance profile name"
  value       = aws_iam_instance_profile.ec2.name
}

