# AWS Region
variable "aws_region" {
  description = "The AWS region to create resources"
  type        = string
  default     = "us-east-1"
}

# VPC CIDR Block
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnet 1 CIDR Block
variable "subnet1_cidr" {
  description = "The CIDR block for the first subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# Subnet 2 CIDR Block
variable "subnet2_cidr" {
  description = "The CIDR block for the second subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# SSH Key Name
variable "key_name" {
  description = "The name of the SSH key pair to access the EC2 instance"
  type        = string
  default     = "linux-key-pair"  # Change to your actual SSH key name
}
