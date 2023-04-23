
# 1. creating vpc 
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr //  ipv4 cidr block for vpc
  enable_dns_support   = true         //  gives you an internal domain name
  enable_dns_hostnames = true         //  gives you an internal host name
  instance_tenancy     = "default"

  tags = {
    Name                                               = "${var.environment}-vpc"
    Environment                                        = "${var.environment}"
    "kubernetes.io/cluster/${var.environment}_ekscluster" = "shared"
  }
}


// ------------------------- Resources for public  subnet--------------------------- //

# 2. creating IGW
resource "aws_internet_gateway" "customIGW" {
  vpc_id = aws_vpc.this.id // attaching custom IGW to custom VPC using vpc-id 

  tags = {
    Name        = "${var.environment}-igw"
    Environment = "${var.environment}"
  }
}

# 3. Creating Public Subnet (create it as per the number of Availaibilty zones) 
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.this.id // assign subnet to custom VPC
  count                   = length(var.public_subnets_cidr)
  cidr_block              = element(var.public_subnets_cidr, count.index) // ipv4 cidr_block for public subnet 
  map_public_ip_on_launch = true                                          // true meanns public subnet will create
  availability_zone       = element(var.availability_zones, count.index)
  tags = {
    Name                                               = "${var.environment}-${element(var.availability_zones, count.index)}-public-subnet"
    Environment                                        = "${var.environment}"
    "kubernetes.io/cluster/${var.environment}-cluster" = "shared"
    "kubernetes.io/role/elb"                           = 1
  }
}

# 4 Create Route Table for public subnet -->> public_route_table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name        = "${var.environment}-public-route-table"
    Environment = "${var.environment}"
  }
}

# 4.1 providing route for internet gateway (IGW is always provided for public route table not for private)
resource "aws_route" "route_to_igw" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.customIGW.id
}

# 4.2 Route table associations (if there is n AZS, n subnet will be created and RTA will also be n)
resource "aws_route_table_association" "public_RTA" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}


// ------------------------- Resources for private subnet--------------------------- //


# Elastic IP for NAT
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.customIGW] // means if igw exits it will exists otherwise not 
  tags = {
    "Name" = "${var.environment}_elastic_ip"
  }
}

#  Creating nat gateway in public subnet but for private subnet
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0) // nat gateway will be created in public subnet (check subnet_id is of public subnet)
  depends_on    = [aws_internet_gateway.customIGW]          // exists only if igw exists
  tags = {
    Name        = "${var.environment}_nat_gateway"
    Environment = "${var.environment}"
  }
}


# Creating Private subnet and associate with vpc using vpc_id (create it as per the number of Availaibilty zones) 
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.this.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-private-subnet"
    Environment = "${var.environment}"
    "kubernetes.io/cluster/${var.environment}-cluster" = "shared"
    "kubernetes.io/role/internal-elb"              = 1
  }
}


#  Creating Routing table for private subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.environment}-private-route-table"
    Environment = "${var.environment}"
  }
}

# Providing route to private subnet using nat gateway
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

# route table association of private subnet to private route table (that's why subnet_id as well as route_table_id is provided)
#  (if there is n AZS, n subnet will be created and RTA will also be n)
resource "aws_route_table_association" "private_RTA" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_route_table.id
}
