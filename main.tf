terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.9.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "tf_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "tf_vpc"
  }
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_launch_template" "tf-lt" {
  name                   = "cloudfive-lt"
  instance_type          = "t2.micro"
  key_name               = "awsrskaradag"
  image_id               = lookup(var.ami,var.aws_region)
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  user_data              = filebase64("./script.sh")
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "CloudFive Selcuk App"
    }
  }
}

resource "aws_lb_target_group" "tf_target" {
  name        = "tf-lb-tg"
  port        = 6161
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.tf_vpc.id
  health_check {
    protocol            = "HTTP"         # default HTTP
    port                = "6161" # default
    unhealthy_threshold = 2              # default 3
    healthy_threshold   = 5              # default 3
    interval            = 20             # default 30
    timeout             = 5              # default 10
  }
}

resource "aws_lb" "tf_lb" {
  name               = "tf-lb"
  load_balancer_type = "application"
  internal           = false # default true 
  security_groups    = [aws_security_group.elb_sg.id]
  subnets            = [aws_subnet.public[0].id,aws_subnet.public[1].id]
  ip_address_type    = "ipv4"
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.tf_lb.arn # required
  default_action {                     # required 
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf_target.arn
  }
  port     = "6161"
  protocol = "HTTP"
}


resource "aws_autoscaling_group" "tf-asg" {
  name                      = "tf-cloudfiveapp"
  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 1
  health_check_type         = "ELB"
  health_check_grace_period = 600
  target_group_arns         = [aws_lb_target_group.tf_target.arn]
  vpc_zone_identifier       = [aws_subnet.public[0].id,aws_subnet.public[1].id]
  launch_template {
    id      = aws_launch_template.tf-lt.id
    version = aws_launch_template.tf-lt.latest_version
  }
}

resource "aws_db_subnet_group" "default" {
  name        = "aws-db-subnet-group"
  description = "Terraform example RDS subnet group"
  subnet_ids  = [aws_subnet.private[0].id,aws_subnet.private[1].id]
}

resource "aws_db_instance" "tf_rds" {
  engine                      = "mysql"
  engine_version              = "8.0.19"
  allocated_storage           = 20
  db_subnet_group_name        = "${aws_db_subnet_group.default.id}"
  vpc_security_group_ids      = [aws_security_group.db_sg.id]
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  backup_retention_period     = 0
  monitoring_interval         = 0 # default 0
  port                        = 3306
  publicly_accessible         = false # default false
  skip_final_snapshot         = true  # default true
  instance_class              = "db.t2.micro"
  identifier                  = "tf-cloudfivebook-db"
  db_name                     = "cloudfive"
  username                    = "admin"
  password                    = "test12345"

}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "tf_igw"
  }
}


output "instance_url" {
  value = "http://${aws_lb.tf_lb.dns_name}"
}