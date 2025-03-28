# Project-07: Implementation of the Entire Advanced CI/CD Pipeline with Major DevOps Tools

This project sets up a Jenkins CI/CD pipeline on AWS using Terraform. It provisions a Virtual Private Cloud (VPC), subnets, security groups, and EC2 instances for Ansible, Jenkins Master, and Jenkins Agent.

![devops](https://imgur.com/WcCpKVU.png)

## Overview


### These are the steps I followed in the implementation of the entire CI/CD Pipeline
The following tools and technologies have been integrated to automate a full CI/CD pipeline:

1. Infrastructure Provisioning: Terraform for VPC, EC2 instances, security groups.
2. Configuration Management: Ansible for Jenkins configuration and SSH key management.
3. CI/CD Pipeline: Jenkins with multibranch pipeline, GitHub webhook triggers.
4. Code Quality: SonarQube integration for static code analysis.
5. Artifact Management: JFrog Artifactory for storing Docker images and build artifacts.
6. Containerization: Docker for creating container images.
7. Container Orchestration: AWS EKS for Kubernetes container management.
8. Deployment: Deploy Docker images to EKS using Kubernetes resources.
9. Monitoring: Prometheus and Grafana for cluster monitoring.

# Project Struture

DevOps-Project/
│
├── terraform/
│   ├── main.tf                    # Main Terraform file to provision infrastructure
│   ├── variables.tf               # Variables for VPC, Security Groups, etc.
│   └── outputs.tf                 # Outputs from Terraform (IP, VPC ID, etc.)
│
├── ansible/
│   ├── playbooks/
│   │   ├── jenkins_setup.yml      # Playbook to set up Jenkins (Master & Agent)
│   │   ├── ansible_controller.yml # Playbook to configure Ansible Controller
│   │   └── security_setup.yml     # Playbook for security configuration (SSH)
│   ├── inventory/                 # Hosts inventory file for Ansible
│   └── ansible.cfg                # Ansible configuration file
│
├── jenkins/
│   ├── Jenkinsfile                # Jenkins pipeline definition (multibranch, SonarQube, Docker, etc.)
│   ├── jenkins_config.yaml       # Configuration file for Jenkins (e.g., plugins)
│   └── credentials.yml            # Credentials for GitHub, SonarQube, Artifactory, etc.
│
├── sonar/
│   ├── sonar-project.properties   # SonarQube project properties for code analysis
│   └── sonar_config.yml           # SonarQube server configuration for Jenkins integration
│
├── docker/
│   ├── Dockerfile                 # Dockerfile to build your application image
│   └── docker-compose.yml         # Docker Compose file (if needed for local testing)
│
├── eks/
│   ├── terraform_eks.tf           # Terraform script to provision AWS EKS cluster
│   ├── kubernetes_config.yaml    # Kubernetes deployment and service configuration
│   ├── aws-cli-config.sh         # AWS CLI config for Jenkins Slave to connect with AWS
│   └── kubectl-config.sh          # Script to configure kubectl for accessing EKS cluster
│
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus-config.yaml # Prometheus configuration file
│   │   └── prometheus-deployment.yaml # Kubernetes deployment file for Prometheus
│   ├── grafana/
│   │   ├── grafana-config.yaml    # Grafana configuration file
│   │   └── grafana-deployment.yaml # Kubernetes deployment file for Grafana
│   └── helm-charts/               # Helm chart files for deploying Prometheus & Grafana
│
└── README.md                      # Project Overview and Setup Instructions



## Terraform Configuration
### Provider Configuration
```hcl
provider "aws" {
  region = var.aws_region
}
```

### VPC and Networking
```hcl
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MyVPC"
  }
}
```

### EC2 Instance Setup
#### **Ansible Controller**
```hcl
resource "aws_instance" "ansible_controller" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet1.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_ansible_controller.id]

  user_data = <<-EOF
    #!/bin/bash
    set -ex
    sudo yum update -y
    sudo amazon-linux-extras enable ansible2
    sudo yum install -y ansible
    sudo -u ec2-user ssh-keygen -t rsa -b 4096 -f /home/ec2-user/.ssh/ansible_id_rsa -N ""
  EOF

  tags = {
    Name = "AnsibleController"
  }
}
```

#### **Jenkins Master & Agent**
```hcl
resource "aws_instance" "jenkins_master" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet1.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_jenkins_master.id]

  provisioner "local-exec" {
    command = "echo '${aws_instance.jenkins_master.public_ip}' >> /tmp/jenkins_master_ip.txt"
  }

  tags = {
    Name = "JenkinsMaster"
  }
}

resource "aws_instance" "jenkins_agent" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet1.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_jenkins_agent.id]

  provisioner "local-exec" {
    command = "echo '${aws_instance.jenkins_agent.public_ip}' >> /tmp/jenkins_agent_ip.txt"
  }

  tags = {
    Name = "JenkinsAgent"
  }
}
```

## Fixing Issues
### **Self-referential Block Issue**
- The error occurred because `aws_instance.ansible_controller` was trying to reference itself in `user_data`. The fix was to remove `echo "${aws_instance.ansible_controller.public_ip}"` from `user_data`.

### **local-exec Provisioner Path Issue**
- The error was due to the system not finding the `/tmp/` path.
- Solution: Ensure `/tmp/` exists by running:
  ```sh
  mkdir -p /tmp/
  ```
- Alternative: Use Terraform outputs instead of `local-exec` to display the IP addresses:
  ```hcl
  output "jenkins_master_ip" {
    value = aws_instance.jenkins_master.public_ip
  }
  
  output "jenkins_agent_ip" {
    value = aws_instance.jenkins_agent.public_ip
  }
  ```
  Run `terraform output` after `terraform apply` to view the IPs.

## Next Steps
- Configure Jenkins on the Master instance.
- Connect Jenkins Agents to the Master.
- Automate deployments using Ansible.
- Implement security best practices.

## Commands to Deploy
```sh
terraform init
terraform plan
terraform apply -auto-approve
```

## Commands to Destroy
```sh
terraform destroy -auto-approve
```

---
This README provides an overview of the Terraform-based setup for Jenkins and Ansible on AWS. Further documentation will include Jenkins setup and pipeline automation.

