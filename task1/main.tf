provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source              = "./modules/vpc"
  project             = var.project
  env                 = var.env
  vpc_cidr            = var.vpc_cidr
  azs                 = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  allowed_ssh_cidr    = var.allowed_ssh_cidr
  common_tags         = local.common_tags
}

module "ec2" {
  source        = "./modules/ec2"
  project       = var.project
  env           = var.env
  subnet_id     = module.vpc.public_subnet_ids[0]
  sg_id         = module.vpc.public_sg_id
  instance_type = var.instance_type
  key_name      = var.key_name
  common_tags   = local.common_tags
}

module "rds" {
  source        = "./modules/rds"
  project       = var.project
  env           = var.env
  subnet_ids    = module.vpc.private_subnet_ids
  vpc_id        = module.vpc.vpc_id
  ec2_sg_id     = module.vpc.public_sg_id
  db_name       = var.db_name
  db_username   = var.db_username
  db_password   = var.db_password
  common_tags   = local.common_tags
}

output "ec2_public_ip" {
  value = module.ec2.public_ip
}

output "rds_endpoint" {
  value = module.rds.endpoint
}
