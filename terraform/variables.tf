
variable "aws_region" {
  description = "AWS region where infrastructure will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for AWS resource naming and tagging."
  type        = string
  default     = "tech-challenge-3"
}

variable "instance_type" {
  description = "EC2 instance type for the web server."
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "Public IPv4 address or CIDR block authorized to access SSH."
  type        = string

  validation {
    condition = (
      can(cidrhost(var.allowed_ssh_cidr, 0)) &&
      can(regex("^[0-9.]+/32$", var.allowed_ssh_cidr)) &&
      var.allowed_ssh_cidr != "0.0.0.0/32"
    )
    error_message = "Provide a single nonzero IPv4 address using /32 CIDR notation, such as 203.0.113.25/32."
  }
}

variable "key_name" {
  description = "Name of the EC2 key pair used for SSH authentication."
  type        = string
  default     = "tech-challenge-3-key"
}
