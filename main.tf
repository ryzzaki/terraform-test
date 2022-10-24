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
  region = "eu-west-1"
}

resource "aws_instance" "terraform-test-1" {
  ami             = "ami-04e2e94de097d3986" # Ubuntu 20.04 LTS 2022
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.terraform-instances.name]
  user_data       = <<-EOF
                    #!/bin/bash
                    echo "Server 1" > index.html
                    python3 -m http.server 8080 &
                    EOF

  tags = {
    Name = "tf-test-1"
  }
}

resource "aws_instance" "terraform-test-2" {
  ami             = "ami-04e2e94de097d3986" # Ubuntu 20.04 LTS 2022
  instance_type   = "t2.micro"
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
  bucket        = "app-data-assets"
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
  name = "terraform-instances-security-group"
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
  name     = "terraform-target-group"
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

resource "aws_lb_target_group_attachment" "terraform-test-1" {
  target_group_arn = aws_lb_target_group.terraform-instances.arn
  target_id        = aws_instance.terraform-test-1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "terraform-test-2" {
  target_group_arn = aws_lb_target_group.terraform-instances.arn
  target_id        = aws_instance.terraform-test-2.id
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

resource "aws_security_group" "alb" {
  name = "alb-security_group"
}

resource "aws_security_group_rule" "allow_alb_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_alb_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "load_balancer" {
  name               = "web-app-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default_subnet.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_route53_zone" "primary" {
  name = "afterlight.io"
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "afterlight.io"
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
  db_name                    = "afterlight_prod"
  username                   = "root"
  password                   = "this_needs_to_be_at_least_8_characters_long"
  skip_final_snapshot        = true
}
