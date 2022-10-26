terraform {
  cloud {
    organization = "artgangmoney"

    workspaces {
      name = "terraform-ws-test"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "terraform-test-server" {
  # meta argument specifying the number of instances to spin up
  count = var.ec2-instance-count

  ami             = var.ami # Ubuntu 20.04 LTS 2022
  instance_type   = var.ec2-instance-type
  security_groups = [aws_security_group.terraform-instances.name]
  user_data       = <<-EOF
                    #!/bin/bash
                    echo "Server ${count.index}" > index.html
                    python3 -m http.server 8080 &
                    EOF

  tags = {
    Name = "tf-test-${count.index}"
  }
}

resource "aws_instance" "terraform-test-2" {
  ami             = var.ami # Ubuntu 20.04 LTS 2022
  instance_type   = var.ec2-instance-type
  security_groups = [aws_security_group.terraform-instances.name]
  user_data       = <<-EOF
                    #!/bin/bash
                    echo "Server 2" > index.html
                    python3 -m http.server 8080 &
                    EOF

  tags = {
    Name = "tf-test-2"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket        = var.bucket-name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_crypto_conf" {
  bucket = aws_s3_bucket.bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}


resource "aws_security_group" "terraform-instances" {
  name = var.security-group-instances
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.terraform-instances.id

  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "terraform-instances" {
  name     = var.lb-target-group
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "terraform-lb-server-attachment" {
  count = var.ec2-instance-count

  target_group_arn = aws_lb_target_group.terraform-instances.arn
  target_id        = aws_instance.terraform-test-server[count.index].id
  port             = 8080
}

resource "aws_lb_listener_rule" "instances" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform-instances.arn
  }
}

resource "aws_security_group" "application-load-balancer" {
  name = var.security-group-alb
}

resource "aws_security_group_rule" "allow_alb_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.application-load-balancer.id

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_alb_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.application-load-balancer.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "load_balancer" {
  name               = var.lb-name
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default_subnet.ids
  security_groups    = [aws_security_group.application-load-balancer.id]
}

resource "aws_route53_zone" "primary" {
  name = var.domain-name
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain-name
  type    = "A"

  alias {
    name                   = aws_lb.load_balancer.dns_name
    zone_id                = aws_lb.load_balancer.zone_id
    evaluate_target_health = true
  }
}

resource "aws_db_instance" "afterlight_db" {
  allocated_storage          = 10
  auto_minor_version_upgrade = true
  storage_type               = "standard"
  engine                     = "postgres"
  engine_version             = "12"
  instance_class             = "db.t2.micro"
  db_name                    = var.db-name
  username                   = var.db-user
  password                   = var.db-pass
  skip_final_snapshot        = true
}
