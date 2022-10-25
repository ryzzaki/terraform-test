output "terraform-test-1-ip" {
  value = aws_instance.terraform-test-1.public_ip
}

output "terraform-test-2-ip" {
  value = aws_instance.terraform-test-2.public_ip
}

output "db-instance-ip" {
  value = aws_db_instance.afterlight_db.address
}
