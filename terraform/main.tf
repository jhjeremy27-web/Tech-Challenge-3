
# Discover the existing default VPC.
data "aws_vpc" "default" {
  default = true
}

# Discover default subnets in the default VPC.
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Read details of the selected default subnet.
data "aws_subnet" "selected" {
  id = sort(data.aws_subnets.default.ids)[0]
}

# Security group for the EC2 web server.
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  description = "Security group for the Tech Challenge 3 web server"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# Allow SSH only from the authorized public IPv4 address.
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id

  description = "Allow SSH from authorized administrator IP"

  cidr_ipv4   = var.allowed_ssh_cidr
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

# Allow public HTTP access to the web server.
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id

  description = "Allow public HTTP access"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# Allow outbound IPv4 traffic for package installation and updates.
resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.web.id

  description = "Allow outbound IPv4 traffic"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}
