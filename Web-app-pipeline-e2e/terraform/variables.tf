variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment identifier"
  type        = string
  default     = null
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
  default     = "t3.medium"
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

variable "management_key_name" {
  description = "Existing EC2 key pair name used for SSH access to the management instance. Required for Sprint 3 Ansible over SSH."
  type        = string
  default     = null
}

variable "state_bucket" {
  description = "S3 bucket name used to store Terraform state"
  type        = string
  default     = "harish-terraform-state-bucket"
}

variable "lock_table" {
  description = "DynamoDB table name used for Terraform state locking"
  type        = string
  default     = "my-terraform-lock-table"
}
