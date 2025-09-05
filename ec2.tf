provider "aws" {
  region = "ap-south-1" # Change to your preferred region
}

resource "aws_key_pair" "mykey" {
  key_name   = "my-ec2-key"
  public_key = file("~/.ssh/id_rsa.pub") # Path to your SSH public key
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Allow SSH, HTTP, and MongoDB"
  vpc_id      = "vpc-xxxxxxxx" # replace with your VPC id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MongoDB"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ Only for testing, restrict in production
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2" {
  ami           = "ami-085f9c64a9b75eed5" # Ubuntu 22.04 LTS in ap-south-1 (check region-specific AMI)
  instance_type = "t3.micro"
  key_name      = aws_key_pair.mykey.key_name
  security_groups = [aws_security_group.ec2_sg.name]

  user_data = <<-EOF
    #!/bin/bash
    exec > >(tee -a /var/log/ec2_bootstrap.log | logger -t userdata -s 2>/dev/console) 2>&1
    set -euxo pipefail

    echo "===== Starting EC2 Bootstrap at \$(date) ====="

    # Update system & install base deps
    apt-get update -y
    apt-get install -y curl gnupg lsb-release ca-certificates build-essential

    # ---------------------------------------------------------------------
    # Install NVM + Node.js
    # ---------------------------------------------------------------------
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    export NVM_DIR="\$HOME/.nvm"
    . "\$NVM_DIR/nvm.sh"

    echo "Installing Node.js 22..."
    nvm install 22
    node -v
    npm -v

    # ---------------------------------------------------------------------
    # Install Nginx
    # ---------------------------------------------------------------------
    echo "Installing nginx..."
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx

    if systemctl is-active --quiet nginx; then
      echo "✅ Nginx running successfully!"
    else
      echo "❌ Nginx failed to start!"
    fi

    # ---------------------------------------------------------------------
    # Install MongoDB
    # ---------------------------------------------------------------------
    echo "Installing MongoDB..."

    MONGO_KEY="/usr/share/keyrings/mongodb.gpg"
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o "\$MONGO_KEY"

    echo "deb [ arch=amd64,arm64 signed-by=\$MONGO_KEY ] https://repo.mongodb.org/apt/ubuntu \$(lsb_release -sc)/mongodb-org/7.0 multiverse" \
      > /etc/apt/sources.list.d/mongodb-org-7.0.list

    apt-get update -y
    apt-get install -y mongodb-org

    systemctl enable mongod
    systemctl start mongod

    if systemctl is-active --quiet mongod; then
      echo "✅ MongoDB installed and running!"
      mongod --version
    else
      echo "❌ MongoDB installation failed!"
    fi

    echo "===== Bootstrap Completed at \$(date) ====="
  EOF

  tags = {
    Name = "Terraform-EC2-Node-Nginx-MongoDB"
  }
}
