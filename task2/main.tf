module "vpc" {
  source  = "./modules/vpc"
  project = var.project
  env     = var.env
}

module "security" {
  source  = "./modules/security"
  vpc_id  = module.vpc.vpc_id
  project = var.project
  env     = var.env
}

module "iam" {
  source  = "./modules/iam"
  project = var.project
  env     = var.env
}

module "secrets" {
  source  = "./modules/secrets"
  project = var.project
  env     = var.env
}

module "ec2" {
  source               = "./modules/ec2"
  project              = var.project
  env                  = var.env
  subnet_id            = module.vpc.private_subnet_id
  vpc_id               = module.vpc.vpc_id
  instance_type        = var.instance_type
  iam_instance_profile = module.iam.instance_profile
  key_name             = null
}

module "cloudtrail" {
  source     = "./modules/cloudtrail"
  project    = var.project
  env        = var.env
  trail_name = "${local.name_prefix}-trail"
}

module "config" {
  source  = "./modules/config"
  enabled = var.enable_aws_config
  project = var.project
  env     = var.env
}
module "cw_alarms" {
  source         = "./modules/cw_alarms"
  project        = var.project
  env            = var.env
  log_group_name = "/aws/cloudtrail/${var.project}-${var.env}"
}

