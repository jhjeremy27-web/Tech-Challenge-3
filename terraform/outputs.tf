
# EC2 instance identifier.
output "instance_id" {
  description = "ID of the EC2 web server."
  value       = aws_instance.web.id
}

# Public IPv4 address used for SSH and HTTP access.
output "instance_public_ip" {
  description = "Public IPv4 address of the EC2 web server."
  value       = aws_instance.web.public_ip
}

# Public DNS hostname assigned to the instance.
output "instance_public_dns" {
  description = "Public DNS hostname of the EC2 web server."
  value       = aws_instance.web.public_dns
}

# Public HTTP URL for the deployed web server.
output "website_url" {
  description = "HTTP URL of the EC2 web server."
  value       = "http://${aws_instance.web.public_ip}"
}

# SSH command for connecting to the EC2 instance.
output "ssh_command" {
  description = "SSH command for accessing the EC2 web server."
  value       = "ssh -i ~/.ssh/tech-challenge-3 ec2-user@${aws_instance.web.public_ip}"
}

# Name of the provisioned S3 bucket.
output "s3_bucket_name" {
  description = "Name of the private S3 bucket."
  value       = aws_s3_bucket.project.bucket
}

# IAM role attached to the EC2 instance.
output "iam_role_name" {
  description = "Name of the IAM role associated with EC2."
  value       = aws_iam_role.ec2.name
}

# Security group protecting the web server.
output "security_group_id" {
  description = "ID of the EC2 web server security group."
  value       = aws_security_group.web.id
}
