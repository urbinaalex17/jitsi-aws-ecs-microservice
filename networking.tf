# Define Network Mode for Fargate

# Providing a reference to our default VPC
resource "aws_vpc" "jitsi_vpc" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"

  tags = {
    name = "jitsi"
  }
}

# Create subnets
resource "aws_subnet" "subnet_a" {
  vpc_id     = aws_vpc.jitsi_vpc.id
  availability_zone = "us-east-1a"
  cidr_block = "10.1.1.0/24"
}

resource "aws_subnet" "subnet_b" {
  vpc_id     = aws_vpc.jitsi_vpc.id
  availability_zone = "us-east-1b"
  cidr_block = "10.1.2.0/24"
}

resource "aws_subnet" "subnet_c" {
  vpc_id     = aws_vpc.jitsi_vpc.id
  availability_zone = "us-east-1c"
  cidr_block = "10.1.3.0/24"
}

# Create an Internet Gateway to pull Jitsi Images
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.jitsi_vpc.id
}

# Create a route table
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.jitsi_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

}

# Create explicit subnet associations
resource "aws_route_table_association" "subnet_a_route_table" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "subnet_b_route_table" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "subnet_c_route_table" {
  subnet_id      = aws_subnet.subnet_c.id
  route_table_id = aws_route_table.route_table.id
}
