############################
#  VPC
############################

resource "aws_vpc" "aws_project" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  enable_dns_support   = true
  tags = {
    Name = "aws_project"
  }
}

############################
# Internet Gateway
############################

resource "aws_internet_gateway" "aws_igw" {
  vpc_id = aws_vpc.aws_project.id
  tags = {
    Name = "main"
  }
}
############################
# Subnets : public
############################

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets_cidr)
  vpc_id                  = aws_vpc.aws_project.id
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-${count.index + 1}"
  }
}
############################
# Subnets : private
############################

resource "aws_subnet" "private" {
  count                   = length(var.private_subnets_cidr)
  vpc_id                  = aws_vpc.aws_project.id
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "Private-Subnet-${count.index + 1}"
  }
}

############################
# Route table: attach Internet Gateway 
############################

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.aws_project.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_igw.id
  }
  tags = {
    Name = "Public-Route_table"
  }
}

############################
# Route table for Private Subnet's
############################

resource "aws_route_table" "PrivateRT" { # Creating RT for Private Subnet
  vpc_id = aws_vpc.aws_project.id
  route {
    cidr_block           = "0.0.0.0/0" # Traffic from Private Subnet reaches Internet via NAT Gateway
    network_interface_id = aws_network_interface.network_interface.id
    # nat_gateway_id = aws_nat_gateway.NATgw.id
  }
  tags = {
    Name = "Private-Route_table"
  }
}

############################
# Route table association with public subnets
############################

resource "aws_route_table_association" "PublicRTassociation" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

############################
# Route table Association with Private Subnet's
############################

resource "aws_route_table_association" "PrivateRTassociation" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.PrivateRT.id
}

resource "aws_network_interface" "network_interface" {
  subnet_id         = aws_subnet.public[1].id
  source_dest_check = false
  security_groups   = [aws_security_group.nat_security_group.id]

  tags = {
    Name = "nat_instance_network_interface"
  }
}


# resource "aws_internet_gateway" "aws_igw" {
#   vpc_id = aws_vpc.aws_project.id
# }
# resource "aws_eip" "nateIP" {
#   vpc   = true
# }
# # Creating the NAT Gateway using subnet_id and allocation_id
# resource "aws_nat_gateway" "NATgw" {
#   allocation_id = aws_eip.nateIP.id
#   subnet_id = aws_subnet.public.id
# }
resource "aws_vpc_endpoint" "endpoint-s3" {
  vpc_id       = aws_vpc.aws_project.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  #  route_table_ids = ["${aws_route_table.PrivateRT.id}"]
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "my-s3-endpoint"
  }
}
resource "aws_vpc_endpoint_route_table_association" "ft-route-table" {
  route_table_id  = aws_route_table.PrivateRT.id
  vpc_endpoint_id = aws_vpc_endpoint.endpoint-s3.id
}