# Security Group for Ansible Controller
resource "aws_security_group" "sg_ansible_controller" {
  name        = "sg_ansible_controller"
  description = "Allow SSH access for Ansible Controller"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # You can restrict this to your IP range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Jenkins Master
resource "aws_security_group" "sg_jenkins_master" {
  name        = "sg_jenkins_master"
  description = "Allow SSH and HTTP access for Jenkins Master"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_ansible_controller.id] # Allow SSH from Ansible Controller
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP access for Jenkins UI (modify as needed)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Jenkins Agent
resource "aws_security_group" "sg_jenkins_agent" {
  name        = "sg_jenkins_agent"
  description = "Allow SSH access for Jenkins Agent"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_ansible_controller.id] # Allow SSH from Ansible Controller
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
