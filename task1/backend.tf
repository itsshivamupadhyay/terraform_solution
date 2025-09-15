terraform {
  backend "s3" {
    bucket         = "shivam-terraform-state"
    key            = "shivam-devops/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
