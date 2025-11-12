resource "aws_vpc" "main_vpc" {
  cidr_block       = "10.0.0.0/24"
  instance_tenancy = "default"
  tags = {
    Name = "main_vpc"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.0.0/24"  # Same as VPC since you want one big subnet
  
  tags = {
    Name = "main_subnet"
  }
}



resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  
  tags = {
    Name = "main-igw"
  }
}


resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
  
  tags = {
    Name = "main-route-table"
  }
}


resource "aws_route_table_association" "main_rta" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rt.id
}
