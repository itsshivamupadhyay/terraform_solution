# Shivam DevOps Project — Terraform Infrastructure

This project provisions:
- VPC with public & private subnets
- EC2 instance in public subnet
- RDS Postgres instance in private subnet
- Remote state stored in S3 with DynamoDB state locking

---

## 🚀 Usage

cd shivam-devops
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars   # edit values

terraform init \
  -backend-config="bucket=shivam-terraform-statev1" \
  -backend-config="key=shivam-devops/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=terraform-locks"

# optional: workspaces
terraform workspace new staging
terraform workspace select staging

terraform plan -out=tfplan
terraform apply "tfplan"

terraform output
