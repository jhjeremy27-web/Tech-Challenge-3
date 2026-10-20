
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
# Retrieve the current Amazon Linux 2023 x86_64 AMI.
data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
# Register the locally generated SSH public key with EC2.
resource "aws_key_pair" "web" {
  key_name   = var.key_name
  public_key = file(pathexpand("~/.ssh/tech-challenge-3.pub"))

  tags = {
    Name = "${var.project_name}-key"
  }
}
# EC2 instance that will host the Nginx web server.
resource "aws_instance" "web" {
  ami           = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type = var.instance_type

  subnet_id                   = data.aws_subnet.selected.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  key_name             = aws_key_pair.web.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${var.project_name}-web-server"
  }
}
# Retrieve information about the current AWS account.
data "aws_caller_identity" "current" {}
# Private S3 bucket for Tech Challenge 3.
resource "aws_s3_bucket" "project" {
  bucket = "${var.project_name}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  tags = {
    Name = "${var.project_name}-bucket"
  }
}
# Prevent public access to the S3 bucket.
resource "aws_s3_bucket_public_access_block" "project" {
  bucket = aws_s3_bucket.project.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
# Disable ACL-based object ownership management.
resource "aws_s3_bucket_ownership_controls" "project" {
  bucket = aws_s3_bucket.project.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
# Explicitly configure default server-side encryption.
resource "aws_s3_bucket_server_side_encryption_configuration" "project" {
  bucket = aws_s3_bucket.project.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
# Trust policy allowing EC2 to assume the role.
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}
# IAM role for the EC2 instance.
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}
# Attach limited Systems Manager permissions to EC2.
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role = aws_iam_role.ec2.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
# Instance profile used to attach the IAM role to EC2.
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"

  role = aws_iam_role.ec2.name

  tags = {
    Name = "${var.project_name}-ec2-profile"
  }
}