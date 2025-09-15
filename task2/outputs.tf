output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnet_id" { value = module.vpc.public_subnet_id }
output "private_subnet_id" { value = module.vpc.private_subnet_id }
output "security_group_id" { value = module.security.sg_id }
output "instance_id" { value = module.ec2.instance_id }
output "iam_role_name" { value = module.iam.role_name }
output "secret_arn" { value = module.secrets.secret_arn }
output "cloudtrail_bucket" { value = module.cloudtrail.bucket_id }
output "config_bucket" { value = try(module.config.bucket_id, null) }

