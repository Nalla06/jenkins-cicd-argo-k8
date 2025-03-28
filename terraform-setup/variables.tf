# Define the AWS region
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1" # Change if needed
}
variable "key_name" {
  description = "Name of the AWS key pair"
  default     = "linux-key-pair"
}


# Define the VPC CIDR block
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "192.168.0.0/16"
}

# Define the subnet CIDR blocks
variable "subnet1_cidr" {
  description = "The CIDR block for Subnet1"
  type        = string
  default     = "192.168.1.0/24"
}

variable "subnet2_cidr" {
  description = "The CIDR block for Subnet2"
  type        = string
  default     = "192.168.2.0/24"
}


# Define the AMI ID
variable "ami_id" {
  description = "The AMI ID for the instances"
  type        = string
  default     = "ami-0c614dee691cbbf37" # Replace with a preferred AMI
}

# Define the instance type
variable "instance_type" {
  description = "The instance type for the instances"
  type        = string
  default     = "t3.medium"
}

variable "private_key_path" {
  description = "Path to the private SSH key for connecting to EC2 instances"
  type        = string
  default     = "~/.ssh/ansible_ssh"
}

