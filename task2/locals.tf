locals {
  name_prefix = "${var.project}-${var.env}"
  common_tags = {
    Project = var.project
    Env     = var.env
  }
}

