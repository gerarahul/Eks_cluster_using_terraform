resource "aws_security_group" "dynamic_sg" {
  name        = "${var.environment}-default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = aws_vpc.customVPC.id
  tags = {
    Name        = "${var.environment}-default-sg"
    Environment = "${var.environment}"
  }

  dynamic "ingress" {
    for_each = var.ports
    iterator = port
    content {
      from_port   = port.value //imp
      to_port     = port.value //imp
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] // [var.vpc_cidr_block] --> you can also use this to allow limited inbound traffic 
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

