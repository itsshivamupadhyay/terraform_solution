🛡️ Task 2 — Secure AWS Infrastructure with Terraform
🚀 Deployment Guide
Bootstrap the Remote Backend

  We use S3 + DynamoDB for Terraform state & locking.
  
  Run the bootstrap script (one-time):
  
  chmod +x backend_bootstrap.sh
  ./backend_bootstrap.sh us-east-1 shivam-terraform-statev1 terraform-locks
  
  This will:
  
  Create a unique S3 bucket (shivam-terraform-statev1-<account_id>)
  
  Create a DynamoDB table (terraform-locks)
  
  Generate provider.tf with backend config.

Initialize Terraform
  terraform init -upgrade
Validate
  terraform validate
  terraform fmt -recursive
Plan
  terraform plan -out=tfplan
Apply
  terraform apply "tfplan"

🔐 Security Best Practices Implemented

VPC security

Private & public subnets

NAT for private outbound access

VPC Flow Logs enabled to CloudWatch

EC2 security

Instance launched only in private subnet (no public IP)

EBS volumes encrypted with AES-256

IAM role with least privilege (SSM, CWAgent)

Identity & Access Management

No root user usage

IAM roles for services instead of access keys

Fine-grained policies for CloudTrail and Config

Logging & Monitoring

CloudTrail multi-region, logs to encrypted S3 and CloudWatch

CloudWatch Alarm for AccessDenied or UnauthorizedOperation events

VPC Flow Logs

Data Protection

S3 buckets encrypted (AES256)

Secrets Manager with KMS CMK

Enforced bucket policies for CloudTrail

Compliance

AWS Config enabled (recorder + delivery channel)

Continuous compliance tracking

📝 Assumptions & Design Choices

Region: Defaulted to us-east-1 (overridable via var.aws_region).

Networking: Minimal setup with 1 private + 1 public subnet for clarity. Can be expanded for multi-AZ HA.

NAT Gateway: Used for private outbound traffic (note: incurs hourly cost).

Secrets Manager: Secrets are created with a random suffix to avoid collisions if a secret is scheduled for deletion.

CloudTrail Logs to CW: Role and policy created to grant permissions explicitly.

IAM Role for EC2: Designed with least privilege, no broad *:* permissions.

CloudWatch Alarm: Currently set to alarm only. For real-world use, wire it to an SNS topic for notifications.

State Management: Backend is account-scoped to ensure uniqueness.

🗂 Deliverables

✅ Terraform files (.tf):

main.tf, variables.tf, provider.tf, outputs.tf

Modularized under modules/ (vpc, ec2, iam, security, cloudtrail, config, secrets, cw_alarms)

✅ README.md (this file):

Deployment instructions

Security best practices

Assumptions & design choices
