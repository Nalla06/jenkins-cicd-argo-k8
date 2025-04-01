provider "aws" {
  region = var.aws_region
}

# IAM Instance Profile for Jenkins EC2
resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
}

# IAM Role for Jenkins
resource "aws_iam_role" "jenkins_role" {
  name               = "jenkins-instance-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_assume_role_policy.json
}

# IAM Policy for Jenkins (to allow EC2 to interact with other AWS resources)
resource "aws_iam_policy" "jenkins_policy" {
  name        = "jenkins-instance-policy"
  description = "Policy for Jenkins EC2 instance"

  policy = data.aws_iam_policy_document.jenkins_policy_document.json
}

# Attach IAM policy to the EC2 instance role
resource "aws_iam_role_policy_attachment" "jenkins_policy_attachment" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = aws_iam_policy.jenkins_policy.arn
}

# Assume Role Policy for Jenkins EC2 Instance Role
data "aws_iam_policy_document" "jenkins_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM Policy Document for Jenkins EC2 Instance (Example: Full EC2 access)
data "aws_iam_policy_document" "jenkins_policy_document" {
  statement {
    actions   = ["ec2:DescribeInstances", "ec2:StartInstances", "ec2:StopInstances"]
    resources = ["*"]
  }

  statement {
    actions   = ["s3:ListBucket", "s3:GetObject"]
    resources = ["arn:aws:s3:::your-bucket-name/*"]
  }
}

# VPC Creation
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MyVPC"
  }
}

# Subnets Creation
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.subnet1_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.subnet2_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet2"
  }
}

# Security Group for EC2 Instance (Allow SSH and Jenkins ports)
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Security group for Jenkins server"
  vpc_id      = aws_vpc.my_vpc.id 

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from all IPs (you can limit to your IP for security)
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Internet Gateway for Public Access
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

# EC2 Instance for Jenkins
resource "aws_instance" "jenkins_instance" {
  ami                    = "ami-084568db4383264d4"  # Ubuntu AMI
  instance_type          = "t2.large"
  key_name               = var.key_name  # SSH key name variable
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true
  subnet_id              = aws_subnet.subnet1.id
  iam_instance_profile   = aws_iam_instance_profile.jenkins_instance_profile.name
  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user_data.log 2>&1  # Redirect logs for debugging

    echo "==== Updating System ===="
    sudo apt update && sudo apt upgrade -y

    echo "==== Running Installation Scripts ===="
    wget https://raw.githubusercontent.com/your-repo/install-tools.sh -O /tmp/install-tools.sh
    chmod +x /tmp/install-tools.sh
    /tmp/install-tools.sh

    wget https://raw.githubusercontent.com/your-repo/install-cd-tools.sh -O /tmp/install-cd-tools.sh
    chmod +x /tmp/install-cd-tools.sh
    /tmp/install-cd-tools.sh

    echo "==== Setup Complete ===="
    touch /home/ubuntu/setup_complete
  EOF

  tags = {
    Name = "Jenkins-EC2"
  }
}
  
# EC2 Instance for ArgoCD and Minikube
resource "aws_instance" "argocd_instance" {
  ami                    = "ami-084568db4383264d4"  # Same Ubuntu AMI
  instance_type          = "t2.large"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true
  subnet_id              = aws_subnet.subnet2.id
  iam_instance_profile   = aws_iam_instance_profile.jenkins_instance_profile.name
  user_data              = file("install-cd-tools.sh")  # Separate script for ArgoCD and Minikube

  tags = {
    Name = "ArgoCD-EC2"
  }
}

# Output EC2 Public IP for ArgoCD
output "argocd_instance_public_ip" {
  value = aws_instance.argocd_instance.public_ip
}


# Output EC2 Public IP
output "jenkins_instance_public_ip" {
  value = aws_instance.jenkins_instance.public_ip
}
