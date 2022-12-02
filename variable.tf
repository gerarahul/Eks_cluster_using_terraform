variable "region" {
  description = "The region to launch the bastion host"
}

variable "availability_zones" {
  type        = list(any)
  description = "The az that the resources will be launched"
}

variable "instance_type" {} 

variable "ami_id" {}



variable "environment" {
  description = "Deployment environment"
}

variable "vpc_cidr" {
  description = "CIDR block of the vpc"
}

variable "public_subnets_cidr" {
  type        = list(any)
  description = "The CIDR block for the public subnet"
}

variable "private_subnets_cidr" {
  type        = list(any)
  description = "The CIDR block for the private subnet"
}

// for security group 
variable "ports" {
  type        = list(number)
  description = "enter port numbers which should be open for inbound traffic"
}





