provider "aws" {
  region = var.aws_region
}

# Generate a new SSH key pair
resource "tls_private_key" "ansible_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store the private key in AWS SSM Parameter Store
resource "aws_ssm_parameter" "ansible_ssh_key" {
  name  = "/ssh/ansible-key"
  type  = "SecureString"
  value = tls_private_key.ansible_ssh_key.private_key_pem
}

# Store the public key in AWS SSM Parameter Store
resource "aws_ssm_parameter" "ansible_ssh_pub_key" {
  name  = "/ssh/ansible-key-pub"
  type  = "String"
  value = tls_private_key.ansible_ssh_key.public_key_openssh
}

# Save private key locally for use
resource "local_file" "ansible_ssh_key" {
  content  = tls_private_key.ansible_ssh_key.private_key_pem
  filename = "~/.ssh/ansible_ssh"
}

# Ensure the key is deleted when terraform destroy runs
resource "null_resource" "cleanup_ansible_ssh_key" {
  provisioner "local-exec" {
    command = "rm -f ~/.ssh/ansible_ssh"
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MyVPC"
  }
}

# Create Subnets
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.subnet1_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "Subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.subnet2_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "Subnet2"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "MyInternetGateway"
  }
}

# Create Route Table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "MyRouteTable"
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "subnet1_association" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_route_table_association" "subnet2_association" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create Ansible Controller Instance
resource "aws_instance" "ansible_controller" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.subnet1.id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_ansible_controller.id]

    user_data = <<-EOF
    #!/bin/bash

    # Detect OS and install Ansible accordingly
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" =~ ^(centos|rhel|amzn)$ ]]; then
            sudo yum install -y epel-release
            sudo yum install -y ansible
        elif [[ "$ID" =~ ^(fedora)$ ]]; then
            sudo dnf install -y ansible
        else
            echo "Unsupported Linux distribution: $ID"
            exit 1
        fi
    else
        echo "Cannot determine OS. Exiting."
        exit 1
    fi

    # Set up SSH keys
    mkdir -p /home/ec2-user/.ssh
    echo "${tls_private_key.ansible_ssh_key.private_key_pem}" > /home/ec2-user/.ssh/ansible_ssh
    chmod 600 /home/ec2-user/.ssh/ansible_ssh
    chown ec2-user:ec2-user /home/ec2-user/.ssh/ansible_ssh
    echo "${tls_private_key.ansible_ssh_key.public_key_openssh}" >> /home/ec2-user/.ssh/authorized_keys
    chmod 600 /home/ec2-user/.ssh/authorized_keys
    ssh-keyscan github.com >> /home/ec2-user/.ssh/known_hosts
    chown ec2-user:ec2-user /home/ec2-user/.ssh/known_hosts

    # Create Ansible directory structure
    mkdir -p /home/ec2-user/ansible
    cd /home/ec2-user/ansible

    # Create inventory.ini file with Jenkins Master and Agent details
    cat > /home/ec2-user/ansible/inventory.ini <<EOL
    [jenkins]
    ${aws_instance.jenkins_master.public_ip} ansible_user=ec2-user
    ${aws_instance.jenkins_agent.public_ip} ansible_user=ec2-user

    [jenkins:vars]
    ansible_ssh_private_key_file=/home/ec2-user/.ssh/ansible_ssh
    EOL

    # Set appropriate permissions
    chown -R ec2-user:ec2-user /home/ec2-user/ansible
    chmod 700 /home/ec2-user/ansible
    chmod 600 /home/ec2-user/ansible/inventory.ini

    # Run initial Ansible playbook (Optional: you can link your playbook later)
    # ansible-playbook -i /home/ec2-user/ansible/inventory.ini jenkins_playbook.yml
  EOF

  tags = {
    Name = "Ansiblecontroller"
  }
}
  
# Create Jenkins Master
resource "aws_instance" "jenkins_master" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.subnet1.id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_jenkins_master.id]

  user_data = <<-EOF
    #!/bin/bash
    mkdir -p /home/ec2-user/.ssh
    echo "${tls_private_key.ansible_ssh_key.public_key_openssh}" >> /home/ec2-user/.ssh/authorized_keys
    chmod 600 /home/ec2-user/.ssh/authorized_keys
    chown ec2-user:ec2-user /home/ec2-user/.ssh/authorized_keys
  EOF

  tags = {
    Name = "JenkinsMaster"
  }
}

# Create Jenkins Agent
resource "aws_instance" "jenkins_agent" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.subnet1.id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_jenkins_agent.id]

  user_data = <<-EOF
    #!/bin/bash
    mkdir -p /home/ec2-user/.ssh
    echo "${tls_private_key.ansible_ssh_key.public_key_openssh}" >> /home/ec2-user/.ssh/authorized_keys
    chmod 600 /home/ec2-user/.ssh/authorized_keys
    chown ec2-user:ec2-user /home/ec2-user/.ssh/authorized_keys
  EOF

  tags = {
    Name = "JenkinsAgent"
  }
}