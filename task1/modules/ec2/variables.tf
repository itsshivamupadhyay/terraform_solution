variable "project" { type = string }
variable "env" { type = string }
variable "subnet_id" {}
variable "sg_id" {}
variable "instance_type" { type = string }
variable "key_name" { type = string }
variable "common_tags" { type = map(string) }
