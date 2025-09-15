data "aws_availability_zones" "available" {}

locals {
  name = "${var.project}-${var.env}"
  cidr = "10.20.0.0/16"
  tags = {
    Project = var.project
    Env     = var.env
  }
}

resource "aws_vpc" "this" {
  cidr_block           = local.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "${local.name}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${local.name}-igw" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(local.cidr, 8, 0)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "${local.name}-public-a" })
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(local.cidr, 8, 1)
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = merge(local.tags, { Name = "${local.name}-private-a" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${local.name}-public-rt" })
}

resource "aws_route" "public_inet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(local.tags, { Name = "${local.name}-nat-eip" })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags          = merge(local.tags, { Name = "${local.name}-nat" })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${local.name}-private-rt" })
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_cloudwatch_log_group" "flow" {
  name              = "/vpc/${local.name}/flow-logs"
  retention_in_days = 30
  tags              = local.tags
}

data "aws_iam_policy_document" "flow_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow" {
  name               = "${local.name}-vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "flow_policy" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"]
    resources = [aws_cloudwatch_log_group.flow.arn, "${aws_cloudwatch_log_group.flow.arn}:*"]
  }
}

resource "aws_iam_role_policy" "flow" {
  name   = "${local.name}-vpc-flow-logs-policy"
  role   = aws_iam_role.flow.id
  policy = data.aws_iam_policy_document.flow_policy.json
}

resource "aws_flow_log" "this" {
  log_destination_type = "cloud-watch-logs"
  log_group_name       = aws_cloudwatch_log_group.flow.name
  iam_role_arn         = aws_iam_role.flow.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id
}

