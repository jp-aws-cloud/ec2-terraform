This Terraform script provisions a basic Ubuntu EC2 instance in AWS Mumbai region (`ap-south-1`) with SSH access. Here's a breakdown of what it does and how each part fits together:

---

### 🧩 What This Terraform Script Does

#### ✅ **1. AWS Provider Configuration**
```hcl
provider "aws" {
  region     = "ap-south-1"
  access_key = "..."
  secret_key = "..."
}
```
- Connects Terraform to your AWS account using static credentials (⚠️ not recommended for production — use IAM roles or environment variables instead).
- Targets the Mumbai region.

---

#### 🔑 **2. SSH Key Pair Setup**
```hcl
resource "aws_key_pair" "my_key" {
  key_name   = "harsh-ec2-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}
```
- Registers your local SSH public key with AWS so you can SSH into the EC2 instance.

---

#### 🌐 **3. Security Group for SSH Access**
```hcl
resource "aws_security_group" "ssh_only" {
  ingress { ... }
  egress { ... }
}
```
- Creates a security group that allows inbound SSH (port 22) from **any IP** (`0.0.0.0/0`) — very open, should be restricted in production.
- Allows all outbound traffic.

---

#### 🏗️ **4. VPC and Subnet Discovery**
```hcl
data "aws_vpc" "default" { ... }
data "aws_subnets" "default" { ... }
```
- Uses the default VPC and its subnets for simplicity.
- No need to manually define networking resources.

---

#### 🖥️ **5. EC2 Instance Creation**
```hcl
resource "aws_instance" "vm" {
  ami           = "ami-07f07a6e1060cd2a8"
  instance_type = "t3.micro"
  ...
}
```
- Launches a **t3.micro** EC2 instance using a hardcoded Ubuntu 22.04 AMI.
- Associates the SSH key and security group.
- Assigns a public IP for remote access.

---

#### 📤 **6. Outputs**
```hcl
output "public_ip" { ... }
output "ssh_command" { ... }
```
- Displays the instance's public IP after provisioning.
- Generates a ready-to-use SSH command for login.

---

### ⚠️ Security & Best Practices Notes

- **Hardcoded credentials**: Replace with environment variables or use IAM roles.
- **Open SSH access**: Restrict `cidr_blocks` to your IP or use a bastion host.
- **Hardcoded AMI**: Consider using a dynamic `data "aws_ami"` block to always get the latest Ubuntu image (you’ve commented that out).

---

Would you like me to refactor this into a production-ready module with input variables, dynamic AMI lookup, and tighter security? I can also help you wrap this into a CI/CD pipeline or integrate it with your backup/restore automation.
