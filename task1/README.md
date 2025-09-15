# TASK 1

---

## 📦 Modules

- **VPC**  
  - Creates VPC, subnets, internet gateway, route tables, and security groups.  
  - Exposes outputs for VPC ID, subnet IDs, and public SG.  

- **EC2**  
  - Launches an Amazon Linux 2 EC2 instance in a public subnet.  
  - Associates with a security group that allows SSH access from your IP.  
  - Outputs the public IP.  

- **RDS**  
  - Provisions a PostgreSQL database in private subnets.  
  - Security group only allows inbound traffic from the EC2 security group.  
  - Outputs the DB endpoint.  

---

## 🔑 Prerequisites

Before running Terraform, the following must be created manually in AWS:  

### 1. S3 Bucket for State Storage
Terraform remote state is stored in an S3 bucket.  

- If using **`us-east-1`**:
  ```bash
  aws s3api create-bucket     --bucket shivam-terraform-state     --region us-east-1
  ```

- If using any **other region** (e.g., `us-west-2`):
  ```bash
  aws s3api create-bucket     --bucket shivam-terraform-state     --region us-west-2     --create-bucket-configuration LocationConstraint=us-west-2
  ```

> ⚠️ Bucket names must be globally unique. Replace `shivam-terraform-state` if it’s already taken.

---

### 2. DynamoDB Table for State Locking
This prevents concurrent modifications to the Terraform state.  

```bash
aws dynamodb create-table   --table-name terraform-locks   --attribute-definitions AttributeName=LockID,AttributeType=S   --key-schema AttributeName=LockID,KeyType=HASH   --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1   --region us-east-1
```

---

### 3. Other Requirements
- **Terraform** >= 1.5  
- **AWS CLI** installed and configured (`aws configure`)  
- An **AWS key pair** available for SSH access to EC2  

---

## 🚀 Terraform Usage

### 1. Configure Variables
Copy and edit the variables file:  
```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Update:  
- `key_name` → your AWS key pair name  
- `allowed_ssh_cidr` → your public IP in `/32` format (e.g. `203.0.113.25/32`)  
- `db_password` → strong password  

---

### 2. Initialize Terraform
Run initialization with backend configuration:  
```bash
terraform init   -backend-config="bucket=shivam-terraform-state"   -backend-config="key=shivam-devops/terraform.tfstate"   -backend-config="region=us-east-1"   -backend-config="dynamodb_table=terraform-locks"
```

---

### 3. Workspaces (Multi-Env Support)
Terraform workspaces allow you to separate environments:  

```bash
terraform workspace new staging
terraform workspace select staging
```

---

### 4. Plan & Apply
```bash
terraform plan -out=tfplan
terraform apply "tfplan"
```

---

### 5. View Outputs
```bash
terraform output
```

You will see:  
- `ec2_public_ip` → The public IP of the EC2 instance  
- `rds_endpoint` → The endpoint of the RDS instance  

---

## 📌 Assumptions & Design Choices

- **Networking:**  
  - A single VPC with **2 public** and **2 private** subnets across multiple AZs.  
  - EC2 deployed in public subnet.  
  - RDS deployed in private subnet.  

- **Security:**  
  - SSH allowed only from admin IP (`allowed_ssh_cidr`).  
  - RDS access restricted to EC2 security group.  

- **Remote State:**  
  - Stored in S3.  
  - Locked via DynamoDB.  

- **Defaults:**  
  - EC2 type → `t3.micro` (free-tier friendly).  
  - RDS engine → PostgreSQL, latest available version.  
  - No hard-coded passwords → configurable in `terraform.tfvars`.  
