output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.dev_env_test.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.dev_env_test.public_ip
}

output "public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.dev_env_test.public_dns
}

output "private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.dev_env_test.private_ip
}

output "app_url" {
  description = "URL to access the Flask application"
  value       = "http://${aws_instance.dev_env_test.public_ip}:${var.app_port}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i dev-env-key.pem ec2-user@${aws_instance.dev_env_test.public_ip}"
}