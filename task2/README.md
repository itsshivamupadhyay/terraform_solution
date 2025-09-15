# Task 2 – AWS Cloud Security (Terraform)

Features:
- VPC with public/private subnets, NAT, Flow Logs → CloudWatch
- EC2 in private subnet, IMDSv2-only, encrypted EBS
- IAM role (least privilege: SSM, CW agent, Secrets)
- Restrictive Security Group (no inbound; egress 80/443 only)
- CloudTrail → encrypted S3 + CloudWatch + Alarm
- AWS Config with managed rules
- Secrets Manager with KMS
- Remote backend: S3 + DynamoDB

