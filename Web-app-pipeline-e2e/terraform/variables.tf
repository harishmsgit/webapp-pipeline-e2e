variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment identifier"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for management resources"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into EC2 instances"
  type        = string
  default     = "0.0.0.0/0"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "webapp-eks-cluster"
}

variable "state_bucket" {
  description = "S3 bucket name used to store Terraform state"
  type        = string
  default     = "REPLACE_WITH_TFSTATE_BUCKET"
}

variable "lock_table" {
  description = "DynamoDB table name used for Terraform state locking"
  type        = string
  default     = "REPLACE_WITH_LOCK_TABLE"
}
