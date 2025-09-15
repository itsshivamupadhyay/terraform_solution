variable "project" { type = string }
variable "env" { type = string }
variable "subnet_ids" { type = list(string) }
variable "vpc_id" {}
variable "ec2_sg_id" {}
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}
variable "common_tags" { type = map(string) }
