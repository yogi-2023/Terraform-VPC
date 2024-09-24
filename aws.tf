provider "aws" {
  region     = "us-east-1"
  access_key = "XXXXXX"
  secret_key = "XXXXXX"
}
resource "aws_vpc" "DEV-VPC" {
  cidr_block       = "10.2000.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "DEV-VPC"
  }
}
resource "aws_subnet" "DEV-SUB-PUB-01" {
  vpc_id     = aws_vpc.DEV-VPC.id
  cidr_block = "10.2000.1.0/24"

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
resource "aws_key_pair" "aws-key" {
  key_name   = "aws-key"
  public_key = "XXXXX"
}
resource "aws_instance" "DEV-EC2" {
  ami           = "ami-0bb84b8ffd87024d8"
  instance_type = "t3.micro"
  subnet_id		= aws_subnet.DEV-SUB-PUB-01.id 
  vpc_security_group_ids	= [aws_security_group.DEV-SG.id]
  key_name 		= "aws-key"
  
  tags = {
    Name = "DEV-EC2"
  }
}
resource "aws_instance" "PRD-EC2" {
  ami           = "ami-0bb84b8ffd87024d8"
  instance_type = "t3.micro"
  subnet_id		= aws_subnet.DEV-SUB-PVT-01.id 
  vpc_security_group_ids	= [aws_security_group.DEV-SG.id]
  key_name 		= "aws-key"
  
  tags = {
    Name = "PRD-EC2"
  }
}
resource "aws_eip" "DEV-Public-ip" {
  instance = aws_instance.DEV-EC2.id
  domain   = "vpc"
}
resource "aws_eip" "PVT-Public-ip" {
  instance = aws_instance.PRD-EC2.id
  domain   = "vpc"
}
resource "aws_nat_gateway" "PVT-NAT" {
  allocation_id		= aws_eip.PVT-Public-ip.id 
  subnet_id         = aws_subnet.DEV-SUB-PUB-01.id
}
resource "aws_route_table" "PRD-RTB" {
  vpc_id = aws_vpc.DEV-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.PVT-NAT.id
  }
  tags = {
    Name = "PRD-RTB"
  }
}
resource "aws_route_table_association" "PRD-RTB" {
  subnet_id      = aws_subnet.DEV-SUB-PVT-01.id
  route_table_id = aws_route_table.PRD-RTB.id
}
