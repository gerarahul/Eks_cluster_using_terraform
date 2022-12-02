// AWS 
region             = "ap-south-1"
availability_zones = ["ap-south-1a"]
ami_id             = "ami-062df10d14676e201" 
instance_type      = "t2.medium"

// environment
environment = "prod"

// networking
vpc_cidr             = "192.168.0.0/16"
public_subnets_cidr  = ["192.168.0.0/24"]
private_subnets_cidr = ["192.168.10.0/24"]
ports                = [443, 80, 22, 8080]