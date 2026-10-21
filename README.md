# Tech Challenge 3 — Infrastructure as Code with Terraform and Ansible

## Project Overview

This project demonstrates how to provision AWS infrastructure using **Terraform** and configure a Linux web server using **Ansible**.

Terraform provisions an Amazon EC2 instance, an Amazon S3 bucket, and the supporting networking, security, and IAM resources. Ansible connects to the EC2 instance over SSH, installs and configures Nginx, and deploys a simple Hello World webpage.

The objective is to demonstrate a repeatable, automated infrastructure deployment workflow that separates infrastructure provisioning from operating system and application configuration.

### Project Objectives

- Provision an AWS EC2 instance using Terraform.
- Create a private Amazon S3 bucket using Terraform.
- Configure networking and security group rules.
- Configure an IAM role and instance profile for EC2.
- Connect to the EC2 instance using Ansible over SSH.
- Install and manage Nginx using Ansible.
- Deploy a static Hello World application.
- Handle host firewall configuration when applicable.
- Verify the application is publicly accessible over HTTP.
- Validate Terraform configuration and Ansible idempotency.
- Document deployment, troubleshooting, and infrastructure cleanup.

## Technologies Used

| Technology | Purpose |
|---|---|
| AWS EC2 | Hosts the web server |
| AWS S3 | Provides the required private storage bucket |
| AWS VPC | Provides networking for EC2 |
| AWS Security Groups | Controls inbound and outbound network traffic |
| AWS IAM | Provides an EC2 instance role and permissions |
| Terraform | Provisions and manages AWS infrastructure |
| Ansible | Configures the EC2 instance and deploys the application |
| Nginx | Serves the static Hello World webpage |
| Amazon Linux 2023 | Operating system running on EC2 |
| Git and GitHub | Version control and project delivery |
| Bash and curl | Deployment assistance and application validation |

---

# Architecture

## Architecture Overview

The project uses a single EC2 instance in the AWS `us-east-1` region.

Terraform provisions the infrastructure using the existing default VPC and a selected default subnet. The EC2 instance receives a public IPv4 address and uses a security group that permits HTTP access from the internet while restricting SSH to an authorized administrator IPv4 address.

Ansible connects from the local machine to the EC2 instance over SSH and configures the web server.

```text
                     Local Development Machine
                     -------------------------
                     AWS CLI
                     Terraform
                     Ansible
                     SSH Client
                     Git
                              |
                              |
                     AWS API / SSH
                              |
                              v
                AWS Cloud — us-east-1
                ---------------------

                     Default VPC
                          |
                    Default Subnet
                          |
                 Security Group
                 ----------------
                 SSH 22: Admin /32
                 HTTP 80: 0.0.0.0/0
                          |
                          v
                    EC2 Instance
                    ------------
                    Amazon Linux 2023
                    t3.micro
                    Encrypted gp3 volume
                    Nginx Web Server
                    Hello World HTML
                          |
                          |
                       HTTP 80
                          |
                          v
                    Public Internet
                          |
                          v
                     Web Browser
                     Hello, World!


                Additional AWS Resources
                ------------------------

                Private S3 Bucket
                - Block Public Access
                - SSE-S3 Encryption
                - BucketOwnerEnforced

                IAM Role / Instance Profile
                - EC2 Trust Relationship
                - Systems Manager Permissions
```

## Infrastructure Components

### EC2 Instance

The EC2 instance hosts the application.

Configuration:

- Instance type: `t3.micro`
- Operating system: Amazon Linux 2023
- Architecture: x86_64
- Root storage: 8 GiB encrypted gp3
- Public IPv4 address: enabled
- SSH username: `ec2-user`
- Instance Metadata Service: IMDSv2 required

### Networking

The project uses an existing default VPC and default subnet rather than creating a custom VPC.

The selected subnet must have a route to an internet gateway to support public internet access.

### Security Group

Inbound rules:

| Protocol | Port | Source | Purpose |
|---|---|---|---|
| TCP | 22 | Administrator IPv4 `/32` | SSH and Ansible |
| TCP | 80 | `0.0.0.0/0` | Public HTTP access |

Outbound IPv4 traffic is permitted.

### S3 Bucket

Terraform creates an S3 bucket with:

- S3 Block Public Access enabled.
- Bucket-owner-enforced object ownership.
- SSE-S3 encryption using AES256.
- No application objects required.

The S3 bucket is not used to host the website or store Terraform state.

### IAM Role

An IAM role is attached to EC2 through an instance profile.

The role uses an EC2 trust relationship and the AWS-managed `AmazonSSMManagedInstanceCore` policy.

The application does not require direct S3 access.

## Terraform and Ansible Responsibilities

Terraform manages the AWS infrastructure:

- EC2 instance
- S3 bucket
- Security group
- Security group rules
- EC2 key pair
- IAM role
- IAM instance profile
- Supporting resource configuration

Ansible manages the server configuration:

- Nginx installation
- Nginx service management
- HTML application deployment
- Conditional host firewall configuration
- Nginx configuration validation

This separation makes the infrastructure and server configuration independently maintainable.

## Deployment Workflow

1. Clone the GitHub repository.
2. Configure AWS authentication.
3. Generate an SSH key pair.
4. Configure Terraform input variables.
5. Initialize and validate Terraform.
6. Review and apply the Terraform plan.
7. Retrieve the EC2 public IP from Terraform outputs.
8. Configure the Ansible inventory.
9. Execute the Ansible playbook.
10. Validate the public Hello World webpage.

## Architecture Limitations

This project is designed as a technical demonstration rather than a production-ready deployment.

Current limitations include:

- A single EC2 instance.
- No load balancer or automatic failover.
- HTTP rather than HTTPS.
- No Elastic IP.
- Local Terraform state.
- No centralized monitoring or alerting configuration.

The EC2 public IP may change after a stop/start operation.

---

# Prerequisites

## AWS Requirements

An AWS account with sufficient permissions to create and manage:

- EC2 instances and key pairs
- Security groups and related rules
- S3 buckets and bucket security settings
- IAM roles, policies, and instance profiles
- Required supporting AWS resources

The account must have an existing default VPC and a suitable default subnet in the selected region.

The selected subnet must support internet access through an internet gateway.

## Local Tools

Install the following tools on the machine running Terraform and Ansible:

| Tool | Requirement |
|---|---|
| AWS CLI | Version 2 |
| Terraform | Version 1.5.0 or later |
| AWS Terraform Provider | Compatible with `~> 6.0` |
| Ansible | Compatible with the local Python environment |
| Git | Installed |
| OpenSSH | Installed |
| curl | Installed |
| Bash | Available |

Verify the tools:

```bash
aws --version
terraform version
ansible --version
git --version
ssh -V
curl --version
```

## SSH Key Requirements

The project expects the following local SSH key files:

```text
~/.ssh/tech-challenge-3
~/.ssh/tech-challenge-3.pub
```

Generate the key pair if necessary:

```bash
ssh-keygen -t ed25519 \
  -f ~/.ssh/tech-challenge-3 \
  -C "tech-challenge-3"
```

Restrict access to the private key:

```bash
chmod 600 ~/.ssh/tech-challenge-3
```

Terraform registers the public key with AWS.

The private key remains on the local machine and must never be committed to Git.

## Network Requirements

The local machine must be able to establish SSH connections to EC2 on TCP port 22.

The deployed EC2 instance must support outbound access for package installation.

The application must be publicly accessible over TCP port 80.

---

# Repository Structure

```text
tech-challenge-3/
├── .gitignore
├── README.md
├── terraform/
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── .terraform.lock.hcl
├── ansible/
│   ├── inventory.ini.example
│   ├── playbook.yml
│   └── files/
│       └── index.html
└── scripts/
    └── validate-website.sh
```

## Terraform Files

### `terraform/main.tf`

Defines the AWS infrastructure, including:

- Default VPC and subnet data sources
- Security group and security group rules
- Amazon Linux 2023 AMI lookup
- EC2 key pair
- EC2 instance
- S3 bucket and security configuration
- IAM role and instance profile

### `terraform/providers.tf`

Defines the Terraform version requirements, AWS provider configuration, deployment region, and default resource tags.

### `terraform/variables.tf`

Defines configurable Terraform inputs, including the AWS region, project name, instance type, authorized SSH CIDR, and EC2 key pair name.

### `terraform/outputs.tf`

Exports infrastructure information needed for validation and Ansible configuration.

### `terraform/terraform.tfvars.example`

Provides an example configuration that can be copied to a local `terraform.tfvars` file.

### `terraform/.terraform.lock.hcl`

Records the selected Terraform provider dependencies and checksums.

This file should be committed to version control.

## Ansible Files

### `ansible/inventory.ini.example`

Provides the example Ansible inventory structure.

### `ansible/playbook.yml`

Defines the server configuration tasks.

### `ansible/files/index.html`

Contains the static Hello World application.

## Validation Script

### `scripts/validate-website.sh`

Validates the deployed website by checking its HTTP response and expected Hello World content.

## Local Files Excluded from Git

The following files and directories are environment-specific or potentially sensitive and should not be committed:

```text
terraform/terraform.tfvars
terraform/terraform.tfstate
terraform/terraform.tfstate.backup
terraform/.terraform/
terraform/deployment.tfplan
terraform/destroy.tfplan
ansible/inventory.ini
validation-evidence/
```

AWS credentials and SSH private keys must also remain outside the repository.

---

# AWS Authentication

Terraform uses the AWS provider's supported credential chain.

Authentication can be provided through a configured AWS CLI profile, temporary credentials, IAM Identity Center, or another supported mechanism.

## Using an AWS CLI Profile

If using a named profile:

```bash
export AWS_PROFILE=tech-challenge-3
```

For an access-key-based profile, initial configuration can be performed using:

```bash
aws configure --profile tech-challenge-3
```

IAM Identity Center users should use the appropriate AWS SSO configuration and login workflow instead.

Verify the active AWS identity:

```bash
aws sts get-caller-identity
```

Confirm the correct account before creating infrastructure.

The Terraform configuration defaults to:

```text
us-east-1
```

Never hardcode AWS access keys or secret access keys in Terraform files.

---

# Deployment Guide

The following instructions describe how to deploy the project from a fresh clone.

Unless otherwise specified, commands are executed from the repository root.

## 1. Clone the Repository

Clone the private GitHub repository:

```bash
git clone git@github.com:YOUR_GITHUB_USERNAME/tech-challenge-3.git
cd tech-challenge-3
```

Replace `YOUR_GITHUB_USERNAME` with the repository owner.

An HTTPS clone URL may also be used if GitHub SSH authentication is not configured.

Because the repository is private, the cloning account must have access.

## 2. Verify AWS Authentication

```bash
aws sts get-caller-identity
```

Confirm that the identity belongs to the intended AWS account.

## 3. Prepare the SSH Key

If the key pair does not already exist:

```bash
ssh-keygen -t ed25519 \
  -f ~/.ssh/tech-challenge-3 \
  -C "tech-challenge-3"
```

Then:

```bash
chmod 600 ~/.ssh/tech-challenge-3
```

The public key will be registered with AWS during Terraform deployment.

## 4. Configure Terraform Variables

Copy the example file:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Retrieve your current public IPv4 address:

```bash
curl -4 https://checkip.amazonaws.com
```

Edit the local configuration:

```bash
nano terraform/terraform.tfvars
```

Example:

```hcl
aws_region       = "us-east-1"
project_name     = "tech-challenge-3"
instance_type    = "t3.micro"
allowed_ssh_cidr = "YOUR_PUBLIC_IPV4/32"
key_name         = "tech-challenge-3-key"
```

Replace `YOUR_PUBLIC_IPV4` with your actual public IPv4 address.

For example:

```hcl
allowed_ssh_cidr = "203.0.113.25/32"
```

The example address is for documentation only.

The `/32` CIDR restricts SSH access to a single IPv4 address.

### Terraform Input Variables

| Variable | Description |
|---|---|
| `aws_region` | AWS region used for deployment |
| `project_name` | Resource naming and tagging |
| `instance_type` | EC2 instance type |
| `allowed_ssh_cidr` | Administrator IPv4 address authorized for SSH |
| `key_name` | EC2 key pair name |

The actual `terraform.tfvars` file is excluded from Git.

## 5. Initialize Terraform

```bash
terraform -chdir=terraform init
```

This initializes the working directory and downloads the required provider dependencies.

Check formatting:

```bash
terraform -chdir=terraform fmt -check
```

Validate configuration:

```bash
terraform -chdir=terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

## 6. Review the Terraform Plan

Create a saved execution plan:

```bash
terraform -chdir=terraform plan -out=deployment.tfplan
```

Inspect the plan:

```bash
terraform -chdir=terraform show deployment.tfplan
```

Review the proposed EC2, S3, IAM, networking, and security resources.

For the initial deployment, this implementation is expected to create 13 Terraform-managed resources.

Do not proceed if the plan includes unexpected destructive or unrelated changes.

## 7. Deploy AWS Infrastructure

Apply the saved plan:

```bash
terraform -chdir=terraform apply deployment.tfplan
```

Terraform provisions the required AWS resources.

After deployment, inspect the outputs:

```bash
terraform -chdir=terraform output
```

At this stage, the infrastructure exists, but the application may not yet be configured.

Ansible performs that work next.

---

# Terraform Outputs

The configuration exports the following values:

| Output | Purpose |
|---|---|
| `instance_id` | EC2 instance ID |
| `instance_public_ip` | EC2 public IPv4 address |
| `instance_public_dns` | EC2 public DNS hostname |
| `website_url` | Public HTTP URL |
| `ssh_command` | SSH connection command |
| `s3_bucket_name` | S3 bucket name |
| `iam_role_name` | IAM role name |
| `security_group_id` | EC2 security group ID |

Display all outputs:

```bash
terraform -chdir=terraform output
```

Retrieve the EC2 public IP:

```bash
terraform -chdir=terraform output -raw instance_public_ip
```

Retrieve the website URL:

```bash
terraform -chdir=terraform output -raw website_url
```

Retrieve the S3 bucket name:

```bash
terraform -chdir=terraform output -raw s3_bucket_name
```

These outputs provide the connection information required by Ansible and the validation process.

---

# Ansible Configuration and Application Deployment

## 8. Configure the Ansible Inventory

Copy the example inventory:

```bash
cp ansible/inventory.ini.example ansible/inventory.ini
```

Retrieve the EC2 public IPv4 address:

```bash
EC2_PUBLIC_IP=$(terraform -chdir=terraform output -raw instance_public_ip)
```

The inventory should have the following structure:

```ini
[webservers]
webserver ansible_host=YOUR_EC2_PUBLIC_IP

[webservers:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/tech-challenge-3
ansible_port=22
ansible_connection=ssh
```

Replace `YOUR_EC2_PUBLIC_IP` with the Terraform output.

Alternatively, generate the local inventory automatically:

```bash
cat > ansible/inventory.ini <<EOF
[webservers]
webserver ansible_host=${EC2_PUBLIC_IP}

[webservers:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/tech-challenge-3
ansible_port=22
ansible_connection=ssh
EOF
```

Verify the inventory:

```bash
ansible-inventory \
  -i ansible/inventory.ini \
  --graph
```

Expected: the `webservers` group contains the `webserver` host.

The actual inventory file is excluded from Git.

## 9. Verify SSH Connectivity

Connect to EC2:

```bash
ssh -i ~/.ssh/tech-challenge-3 \
  -o IdentitiesOnly=yes \
  ec2-user@"$EC2_PUBLIC_IP"
```

Verify the operating system:

```bash
cat /etc/os-release
```

Exit:

```bash
exit
```

Keep SSH host key verification enabled and verify unfamiliar fingerprints through a trusted method.

## 10. Verify Ansible Connectivity

Run:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -m ansible.builtin.ping
```

Expected output includes:

```text
"ping": "pong"
```

The Ansible ping module verifies remote module execution through the configured connection. It is not an ICMP network ping.

## 11. Understand the Ansible Playbook

The main playbook is located at:

```text
ansible/playbook.yml
```

It targets the `webservers` group and uses privilege escalation for administrative tasks.

### Nginx Installation

The `ansible.builtin.dnf` module ensures that Nginx is installed on Amazon Linux 2023.

### Nginx Service Management

The `ansible.builtin.systemd_service` module ensures Nginx is running and enabled at boot.

### HTML Application Deployment

The `ansible.builtin.copy` module deploys:

```text
ansible/files/index.html
```

To:

```text
/usr/share/nginx/html/index.html
```

The destination file uses:

```text
Owner: root
Group: root
Permissions: 0644
```

### Firewall Configuration

The playbook checks whether firewalld is installed and active.

If applicable, it ensures that HTTP is permitted and reloads the firewall when a permanent rule changes.

AWS security groups provide an additional, independent network access control layer.

### Nginx Configuration Validation

The playbook executes:

```bash
nginx -t
```

To verify the Nginx configuration.

### Idempotency

The playbook uses declarative Ansible modules and conditional change detection.

Repeated execution should not make unnecessary changes when the server already matches the desired configuration.

## 12. Validate the Ansible Playbook

Check syntax:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yml \
  --syntax-check
```

Review tasks:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yml \
  --list-tasks
```

## 13. Execute the Playbook

Run:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yml
```

A successful execution should report:

```text
unreachable=0
failed=0
```

The first execution may report changed tasks while Nginx and the application are configured.

Run the playbook again:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yml
```

When the desired configuration is already present, the second execution should report:

```text
changed=0
unreachable=0
failed=0
```

This demonstrates idempotent configuration management.

---

# Website Access

After the Ansible playbook completes successfully, retrieve the public URL:

```bash
terraform -chdir=terraform output -raw website_url
```

The URL has the format:

```text
http://EC2_PUBLIC_IP
```

Open the URL in a browser.

The page should display:

## Hello, World!

Deployed to AWS EC2 using Terraform and Ansible.

On macOS:

```bash
WEBSITE_URL=$(terraform -chdir=terraform output -raw website_url)

open "$WEBSITE_URL"
```

The application uses HTTP on port 80. HTTPS is not configured for this challenge.

---

# Validation

Validation is performed at three levels:

1. Infrastructure validation using Terraform and AWS CLI.
2. Configuration validation using Ansible and Nginx.
3. Application validation using HTTP requests and the validation script.

## Terraform Validation

Check formatting:

```bash
terraform -chdir=terraform fmt -check
```

Validate configuration:

```bash
terraform -chdir=terraform validate
```

Check for infrastructure drift:

```bash
terraform -chdir=terraform plan
```

After successful deployment with no drift, Terraform should report:

```text
No changes. Your infrastructure matches the configuration.
```

## AWS Resource Validation

List Terraform-managed resources:

```bash
terraform -chdir=terraform state list
```

Retrieve the EC2 instance ID:

```bash
EC2_INSTANCE_ID=$(terraform -chdir=terraform output -raw instance_id)
```

Verify its state:

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --instance-ids "$EC2_INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text
```

Expected:

```text
running
```

Retrieve the S3 bucket name:

```bash
S3_BUCKET_NAME=$(terraform -chdir=terraform output -raw s3_bucket_name)
```

Verify the bucket exists:

```bash
aws s3api head-bucket \
  --bucket "$S3_BUCKET_NAME" \
  --region us-east-1
```

A successful request normally exits without output.

## Security Group Validation

Retrieve the security group ID:

```bash
SECURITY_GROUP_ID=$(terraform -chdir=terraform output -raw security_group_id)
```

Inspect the rules:

```bash
aws ec2 describe-security-group-rules \
  --region us-east-1 \
  --filters "Name=group-id,Values=$SECURITY_GROUP_ID" \
  --output table
```

Verify:

- SSH TCP 22 is restricted to the administrator IPv4 `/32`.
- HTTP TCP 80 is publicly accessible.
- Outbound IPv4 traffic is permitted.

## Ansible Validation

Verify connectivity:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -m ansible.builtin.ping
```

Verify Nginx is running:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -b \
  -m ansible.builtin.command \
  -a "systemctl is-active nginx"
```

Expected:

```text
active
```

Verify Nginx is enabled:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -b \
  -m ansible.builtin.command \
  -a "systemctl is-enabled nginx"
```

Expected:

```text
enabled
```

Validate Nginx configuration:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -b \
  -m ansible.builtin.command \
  -a "nginx -t"
```

## HTTP Validation

Retrieve the website URL:

```bash
WEBSITE_URL=$(terraform -chdir=terraform output -raw website_url)
```

Check HTTP response headers:

```bash
curl -I --max-time 10 "$WEBSITE_URL/"
```

Expected:

```text
HTTP/1.1 200 OK
```

Retrieve the response body:

```bash
curl -fsS --max-time 10 "$WEBSITE_URL/"
```

Verify the HTML contains:

```html
<h1>Hello, World!</h1>
```

## Automated Website Validation

Run:

```bash
./scripts/validate-website.sh
```

Expected output:

```text
PASS: HTTP 200
PASS: Hello World content verified
Website validation successful.
```

## Idempotency Validation

Run the Ansible playbook twice without making intervening changes:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yml
```

On the second execution, the expected recap includes:

```text
changed=0
unreachable=0
failed=0
```

This verifies that repeated execution does not introduce unnecessary configuration changes.

---

# Troubleshooting

The following procedures address common Terraform, AWS, SSH, Ansible, and Nginx issues.

## Terraform Initialization Fails

**Possible causes:**

- Network or DNS connectivity problems.
- Provider version conflicts.
- Incomplete initialization.
- Unsupported Terraform CLI version.

**Diagnostics:**

```bash
terraform version
terraform -chdir=terraform providers
terraform -chdir=terraform init
```

**Resolution:**

Verify Terraform compatibility and provider constraints. Reinitialize the working directory after resolving the underlying issue.

Do not delete the provider lock file merely to bypass a version conflict.

## AWS Authentication Errors

**Possible symptoms:**

- `InvalidClientTokenId`
- `ExpiredToken`
- `AccessDenied`
- Credentials cannot be located

**Diagnostics:**

```bash
aws sts get-caller-identity
aws configure list
```

**Resolution:**

Verify the AWS profile, refresh expired temporary credentials, and confirm the required IAM permissions.

Never hardcode credentials in Terraform source files.

## Default VPC Not Found

**Diagnostics:**

```bash
aws ec2 describe-vpcs \
  --region us-east-1 \
  --filters "Name=is-default,Values=true"
```

**Resolution:**

Confirm that the selected AWS account and region contain a default VPC.

This implementation assumes an existing default VPC and suitable default subnet.

## EC2 Provisioning Fails

**Possible causes:**

- Insufficient IAM permissions.
- EC2 quota limits.
- Instance capacity or configuration issues.
- Key pair naming conflicts.
- Invalid subnet or security group configuration.

**Diagnostics:**

```bash
terraform -chdir=terraform plan
terraform -chdir=terraform state list
```

Review the AWS error message before making changes.

A failed Terraform apply may leave successfully created resources in state.

## S3 Bucket Creation Fails

S3 bucket names must be globally unique within the AWS partition.

This project constructs the bucket name using the project name, AWS account ID, and region.

If a naming conflict occurs, inspect the existing bucket and Terraform state before modifying the configuration.

Do not delete a bucket unless its ownership and purpose have been confirmed.

## SSH Connection Times Out

**Possible causes:**

- EC2 is not running.
- Public IP has changed.
- SSH security group rule does not authorize the current IP.
- Subnet routing is incorrect.
- Network ACL or host firewall interference.

**Diagnostics:**

```bash
EC2_PUBLIC_IP=$(terraform -chdir=terraform output -raw instance_public_ip)

curl -4 https://checkip.amazonaws.com
```

Check the EC2 instance:

```bash
EC2_INSTANCE_ID=$(terraform -chdir=terraform output -raw instance_id)

aws ec2 describe-instances \
  --region us-east-1 \
  --instance-ids "$EC2_INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text
```

**Resolution:**

Confirm the EC2 instance is running, update the Ansible inventory if the public IP changed, and verify the SSH security group rule.

If the administrator public IP changed, update `allowed_ssh_cidr`, review the Terraform plan, and apply the intended change.

Do not open SSH to `0.0.0.0/0` as a troubleshooting shortcut.

## SSH Permission Denied

**Possible causes:**

- Incorrect SSH key.
- Incorrect remote username.
- Incorrect private key permissions.
- EC2 key pair mismatch.

**Diagnostics:**

```bash
ls -l ~/.ssh/tech-challenge-3
```

Test SSH:

```bash
ssh -i ~/.ssh/tech-challenge-3 \
  -o IdentitiesOnly=yes \
  ec2-user@"$EC2_PUBLIC_IP"
```

Restrict key permissions:

```bash
chmod 600 ~/.ssh/tech-challenge-3
```

Confirm that the private key corresponds to the public key registered with EC2.

## SSH Host Key Warning

A host key mismatch may indicate that the IP address belongs to a different instance or that the remote host identity changed.

Verify the expected host fingerprint using a trusted method before updating the local known-hosts entry.

Do not disable host key checking globally.

## Ansible Reports UNREACHABLE

**Diagnostics:**

```bash
ansible-inventory \
  -i ansible/inventory.ini \
  --host webserver
```

Run with verbose logging:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -m ansible.builtin.ping \
  -vvv
```

**Resolution:**

Verify the inventory IP, SSH username, private key, security group, and remote connectivity.

## Ansible Privilege Escalation Fails

**Diagnostics:**

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -b \
  -m ansible.builtin.command \
  -a "whoami"
```

Expected:

```text
root
```

Verify that the configured remote user has the required sudo permissions.

## Ansible Reports Changes on Every Run

Run:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yml \
  --diff
```

Inspect the task reporting changes.

Review module state declarations, file content, service configuration, and command-based change detection.

For an unchanged server, the second execution should normally report `changed=0`.

## Nginx Installation Fails

Verify the remote operating system:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -m ansible.builtin.command \
  -a "cat /etc/os-release"
```

Confirm that the instance is running Amazon Linux 2023 and has outbound connectivity for package installation.

## Website Does Not Load

Retrieve the website URL:

```bash
WEBSITE_URL=$(terraform -chdir=terraform output -raw website_url)
```

Test HTTP:

```bash
curl -I --max-time 10 "$WEBSITE_URL/"
```

Check Nginx:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -b \
  -m ansible.builtin.command \
  -a "systemctl is-active nginx"
```

Test HTTP locally on EC2:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -m ansible.builtin.command \
  -a "curl -I http://127.0.0.1/"
```

If localhost works but the public URL fails, investigate AWS networking, firewall rules, and the Nginx listening address.

If localhost fails, investigate Nginx and application configuration.

## Website Returns Connection Refused

Check listening ports:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -b \
  -m ansible.builtin.command \
  -a "ss -lntp"
```

Confirm Nginx is listening on TCP port 80.

## Website Returns 403 or 404

Verify the deployed file:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -m ansible.builtin.command \
  -a "ls -l /usr/share/nginx/html/index.html"
```

Inspect its contents:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -m ansible.builtin.command \
  -a "cat /usr/share/nginx/html/index.html"
```

Validate Nginx:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -b \
  -m ansible.builtin.command \
  -a "nginx -t"
```

## Website Displays Incorrect Content

Inspect the local source:

```bash
cat ansible/files/index.html
```

Rerun the playbook:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yml
```

## Nginx Logs

Recent access logs:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -b \
  -m ansible.builtin.command \
  -a "tail -n 20 /var/log/nginx/access.log"
```

Recent error logs:

```bash
ansible webservers \
  -i ansible/inventory.ini \
  -b \
  -m ansible.builtin.command \
  -a "tail -n 20 /var/log/nginx/error.log"
```

After resolving an issue, rerun:

```bash
./scripts/validate-website.sh
```

---

# Security Considerations

## Network Security

- SSH is restricted to an authorized administrator IPv4 `/32`.
- Public inbound traffic is limited to HTTP on TCP port 80.
- AWS security groups are managed by Terraform.
- Host firewall configuration is managed by Ansible when applicable.

## EC2 Security

- SSH key-based authentication is used.
- The SSH private key remains on the local machine.
- The EC2 root volume is encrypted.
- IMDSv2 is required.
- An IAM instance profile provides Systems Manager permissions.

## S3 Security

- Block Public Access is enabled.
- Bucket-owner-enforced object ownership is configured.
- SSE-S3 encryption is enabled.
- The bucket is not used for website hosting or Terraform state.

## Credential Protection

AWS credentials, SSH private keys, Terraform state, and saved plans must not be committed to Git.

Terraform state may contain sensitive information and must be protected.

The actual Ansible inventory and local Terraform variable values are excluded from version control.

## Production Limitations

This project is intended as a technical demonstration.

It uses HTTP rather than HTTPS and a single EC2 instance without automatic failover.

A production deployment would require additional controls for security, monitoring, availability, backup, and operational management.

---

# Infrastructure Cleanup

AWS resources may incur charges while they remain deployed.

Once the project is no longer needed, Terraform can remove the infrastructure it manages.

**Do not destroy the environment until the reviewer or mentor has completed any required live validation.**

## 1. Verify the AWS Account

```bash
aws sts get-caller-identity
```

Confirm that the selected identity belongs to the intended AWS account.

## 2. Inspect Terraform State

```bash
terraform -chdir=terraform state list
```

Review the managed resources.

## 3. Create a Destroy Plan

```bash
terraform -chdir=terraform plan \
  -destroy \
  -out=destroy.tfplan
```

Inspect the plan:

```bash
terraform -chdir=terraform show destroy.tfplan
```

Confirm that only the intended project resources are scheduled for deletion.

## 4. Destroy the Infrastructure

After confirming that the resources are no longer required:

```bash
terraform -chdir=terraform apply destroy.tfplan
```

Terraform removes managed AWS resources according to their dependencies.

This operation is destructive and may permanently remove data.

## 5. Verify Cleanup

Check Terraform state:

```bash
terraform -chdir=terraform state list
```

No managed resources should remain after a successful destroy.

Verify the project's AWS resources have been removed.

The existing default VPC and subnet are not destroyed because they are referenced as data sources rather than managed Terraform resources.

## 6. Preserve the Repository

Keep the GitHub repository, Terraform configuration, Ansible playbook, HTML source, validation script, and README for future reference.

The local SSH private key is not removed by Terraform.

## Cleanup Notes

The S3 bucket is expected to be empty. If objects have been added, bucket deletion may fail until they are removed.

Review any unexpected Terraform errors before attempting manual AWS cleanup.

Do not delete unrelated AWS resources.

---

# Project Completion Criteria

The project is considered successfully deployed when:

- Terraform configuration passes formatting and validation.
- Terraform provisions the required EC2 instance and S3 bucket.
- EC2 is running and accessible over SSH.
- The S3 bucket exists with the intended security configuration.
- The security group permits HTTP and restricts SSH.
- Terraform outputs expose the expected resource information.
- Ansible connects successfully.
- Ansible installs and configures Nginx.
- Nginx is active and enabled at boot.
- The Hello World HTML file is deployed.
- The public website returns HTTP 200.
- The webpage displays **Hello, World!**
- Repeated Ansible execution is idempotent.
- No credentials, SSH private keys, or Terraform state files are committed.
- The README documents deployment, validation, troubleshooting, and cleanup.

## Final Validation Commands

From the repository root:

```bash
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
terraform -chdir=terraform plan
```

Run Ansible:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yml
```

Validate the website:

```bash
./scripts/validate-website.sh
```

Expected results:

- Terraform validates successfully.
- Terraform reports no unexpected infrastructure changes.
- Ansible completes without failed or unreachable hosts.
- Repeated Ansible execution reports `changed=0`.
- The website returns HTTP 200 and displays Hello World.

---

# Submission

The completed project is maintained in a public GitHub repository.

The final submission includes:

1. The public GitHub repository URL.
2. The deployed application URL.

The AWS infrastructure should remain available until the reviewer completes any required live validation.

After review, the infrastructure can be removed using the documented Terraform cleanup procedure.

---

# Summary

This project demonstrates an automated AWS infrastructure and application deployment workflow using Terraform and Ansible.

Terraform manages infrastructure provisioning, including EC2, S3, IAM, and networking resources.

Ansible configures the EC2 instance, installs Nginx, manages services, and deploys the Hello World webpage.

The project also demonstrates infrastructure validation, configuration idempotency, security-conscious access controls, troubleshooting, documentation, and infrastructure lifecycle management.