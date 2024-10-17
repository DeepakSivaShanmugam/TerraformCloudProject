terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Ohio"
  }
}

resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availabilty_zone = "us-east-2a"

  tags = {
    Name = "Ohio-pub"
  }
}

resource "aws_subnet" "prisub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availabilty_zone = "us-east-2b"

  tags = {
    Name = "Ohio-pri"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "ohioInternetgw"
  }
}

resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "ohio-rt"
  }
}

resource "aws_route_table_association" "pubsubpubrtassoc" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrt.id
}

resource "aws_eip" "myeip" {
}

resource "aws_nat_gateway" "mygw" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.pubsup.id

  tags = {
    Name = "gw Ohio"
  }
}

resource "aws_route_table" "prirt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "ohio-prirt"
  }
}

resource "aws_route_table_association" "prirtprisubassoc" {
  subnet_id      = aws_subnet.prisub.id
  route_table_id = aws_route_table.prirt.id
}

resource "aws_security_group" "pubsg" {
  name        = "pubsg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "OHIO-pub"
  }
}

resource "aws_security_group" "prisg" {
  name        = "prisg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["10.0.1.0/24"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "OHIO-pri"
  }
}   

resource "aws_instance" "pub_instance" {
  ami                                             = "ami-052cef05d01020f1d"
  instance_type                                   = "t2.micro"
  availability_zone                               = "ap-south-1a"
  associate_public_ip_address                     = "true"
  vpc_security_group_ids                          = [aws_security_group.pubsg.id]
  subnet_id                                       = aws_subnet.pubsub.id 
  key_name                                        = "GIT_KEY"
  
    tags = {
    Name = "HDFCBANK WEBSERVER"
  }
}

resource "aws_instance" "pri_instance" {
  ami                                             = "ami-052cef05d01020f1d"
  instance_type                                   = "t2.micro"
  availability_zone                               = "ap-south-1b"
  associate_public_ip_address                     = "false"
  vpc_security_group_ids                          = [aws_security_group.prisg.id]
  subnet_id                                       = aws_subnet.prisub.id 
  key_name                                        = "GIT_KEY"
  
    tags = {
    Name = "HDFCBANK APPSERVER"
  }
}
