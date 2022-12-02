resource "aws_key_pair" "terraform_aws_key" {
  key_name   = "terraform_aws_key"
  public_key = file("C:/ADMIN/keys/terraform_aws_key.pub")
  tags = {
    Name        = "${var.environment}-key"
    Environment = "${var.environment}"
  }
}

