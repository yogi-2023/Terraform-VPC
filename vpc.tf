provider "aws" {
  region     = "us-east-1"
  access_key = "XXXXXX"
  secret_key = "XXXXXX"
}
resource "aws_vpc" "DEV-VPC" {
  cidr_block       = "10.200.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "DEV-VPC"
  }
}
resource "aws_subnet" "DEV-SUB-PUB-01" {
  vpc_id     = aws_vpc.DEV-VPC.id
  cidr_block = "10.200.1.0/24"

  tags = {
    Name = "DEV-SUB-PUB-01"
  }
}
resource "aws_subnet" "DEV-SUB-PVT-01" {
  vpc_id     = aws_vpc.DEV-VPC.id
  cidr_block = "10.200.2.0/24"

  tags = {
    Name = "DEV-SUB-PVT-01"
  }
}
resource "aws_security_group" "DEV-SG" {
  name        = "DEV-SG"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.DEV-VPC.id

  tags = {
    Name = "DEV-SG"
  }
}
resource "aws_vpc_security_group_ingress_rule" "DEV-SG" {
  security_group_id = aws_security_group.DEV-SG.id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
resource "aws_vpc_security_group_egress_rule" "DEV-SG" {
  security_group_id = aws_security_group.DEV-SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
resource "aws_internet_gateway" "DEV-IGW" {
  vpc_id = aws_vpc.DEV-VPC.id

  tags = {
    Name = "DEV-IGW"
  }
}
resource "aws_route_table" "DEV-RTB" {
  vpc_id = aws_vpc.DEV-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.DEV-IGW.id
  }
  tags = {
    Name = "DEV-RTB"
  }
}
resource "aws_route_table_association" "DEV-RTB" {
  subnet_id      = aws_subnet.DEV-SUB-PUB-01.id
  route_table_id = aws_route_table.DEV-RTB.id
}
