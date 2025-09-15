resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.env}-db-subnet"
  subnet_ids = var.subnet_ids
  tags       = var.common_tags
}

resource "aws_security_group" "rds_sg" {
  name   = "${var.project}-${var.env}-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ec2_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project}-${var.env}-rds-sg" })
}

resource "aws_db_instance" "this" {
  allocated_storage    = 20
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true
  publicly_accessible  = false
  tags                 = merge(var.common_tags, { Name = "${var.project}-${var.env}-rds" })
}
