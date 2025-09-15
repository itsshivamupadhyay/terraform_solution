output "sg_id" {
  description = "ID of the security group for EC2"
  value       = aws_security_group.instance.id
}

