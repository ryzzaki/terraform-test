terraform {
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

resource "aws_instance" "terraform-test" {
  ami           = "ami-04e2e94de097d3986" # Ubuntu 20.04 LTS 2022
  instance_type = "t2.micro"
}
