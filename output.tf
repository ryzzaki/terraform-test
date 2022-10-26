output "terraform-server-ip" {
  // this is using the splat command to destruct the count meta arg
  value = [aws_instance.terraform-test-server.*.public_ip]
}

output "db-instance-ip" {
  value = aws_db_instance.afterlight_db.address
}
