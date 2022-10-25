# AWS Provider

variable "region" {
  description = "AWS Region Value"
  type        = string
  default     = "eu-west-1"
}

# EC2 Related

variable "ami" {
  description = "Amazon Machine Image"
  type        = string
  default     = "ami-04e2e94de097d3986"
}

variable "ec2-instance-type" {
  description = "EC2 Instance Tier"
  type        = string
  default     = "t2.micro"
}

# Load Balancer Related

variable "lb-name" {
  description = "Name of the Load Balancer"
  type        = string
  default     = "app-lb"
}

variable "lb-target-group" {
  description = "Load Balancer Target Group Name"
  type        = string
  default     = "terraform-target-group"
}

# Security Groups Related

variable "security-group-instances" {
  description = "Name of the Security Group Policy for Instances"
  type        = string
  default     = "terraform-instances-security-group"
}

variable "security-group-alb" {
  description = "Name of the Application Load Balancer Security Group Policy"
  type        = string
  default     = "application-load-balancer-security_group"
}

# S3 Related

variable "bucket-name" {
  description = "S3 Bucket Name"
  type        = string
}

# Route53 Related

variable "domain-name" {
  description = "Root/A Record of the Domain Name"
  type        = string
}

# RDS Related

variable "db-name" {
  description = "Database Name"
  type        = string
}

variable "db-user" {
  description = "Database Username"
  type        = string
}

variable "db-pass" {
  description = "Database Password"
  type        = string
  sensitive   = true
}
