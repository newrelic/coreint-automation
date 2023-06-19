data aws_availability_zones available {
  state = "available"
}

resource aws_vpc base_vpc {
  tags = {
    Name = "${var.canary_name} Base Network"
  }

  enable_dns_support   = true
  enable_dns_hostnames = true
  cidr_block           = "${var.network_cidr}"
}

resource aws_default_route_table default_route {
  tags = {
    Name = "${var.canary_name} Default Route Table"
  }
  default_route_table_id = aws_vpc.base_vpc.default_route_table_id

  route = []
}

resource aws_default_security_group default {
  tags = {
    Name = "${var.canary_name} Default Security Group"
  }
  vpc_id = aws_vpc.base_vpc.id

  # ingress from inside of the security group itself
  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  # egress to world
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ########################################### #
#  Public                                     #
# ########################################### #
resource aws_subnet public_subnet {
  tags = {
    Name = "${var.canary_name} Public Subnet"
  }
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  cidr_block = cidrsubnet(aws_vpc.base_vpc.cidr_block, 4, 0)
  vpc_id     = aws_vpc.base_vpc.id
}

resource aws_internet_gateway public {
  tags = {
    Name = "${var.canary_name} Internet Gateway"
  }
  vpc_id = aws_vpc.base_vpc.id
}

resource aws_route_table public {
  tags = {
    Name = "${var.canary_name} Public Route Table"
  }
  vpc_id = aws_vpc.base_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }
}

resource aws_route_table_association public {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_subnet.id
}


# ########################################### #
#  Private                                    #
# ########################################### #
resource aws_eip public {
  vpc = true
}

resource aws_nat_gateway private {
  tags = {
    Name = "${var.canary_name} NAT Gateway"
  }
  subnet_id     = aws_subnet.public_subnet.id
  allocation_id = aws_eip.public.id

  depends_on = [aws_internet_gateway.public]
}

resource aws_subnet private_subnets {
  count             = length(data.aws_availability_zones.available.names)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.canary_name} Private Subnet_${data.aws_availability_zones.available.names[count.index]}"
  }

  map_public_ip_on_launch = false

  cidr_block = cidrsubnet(aws_vpc.base_vpc.cidr_block, 4, 1 + count.index)
  vpc_id     = aws_vpc.base_vpc.id
}

resource aws_route_table private {
  tags = {
    Name = "${var.canary_name} Private Route Table"
  }
  vpc_id = aws_vpc.base_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.private.id
  }
}

resource aws_route_table_association private {
  count          = length(aws_subnet.private_subnets.*.id)
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private_subnets[count.index].id
}

# This security group allows traffic between internal resources and EKS pods
# All resources deployed on the vpc should have the SG added to allow transparent traffic between them
# This was done as a workaround
resource aws_security_group internal_traffic {
  tags = {
    Name = "${var.canary_name} Internal Traffic Security Group"
  }
  name = "${var.canary_name} Internal Traffic Security Group"
  vpc_id = aws_vpc.base_vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    cidr_blocks = ["${var.network_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output common_networking {
  value = {
    aws_vpc = {
      base_vpc = {
        arn = aws_vpc.base_vpc.arn
        id  = aws_vpc.base_vpc.id
      }
    }
    aws_subnet = {
      private_subnets = [for subnet in aws_subnet.private_subnets : { id = subnet.id }]
      public_subnet   = { id = aws_subnet.public_subnet.id }
    }
    aws_default_security_group = {
      default = {
        arn  = aws_default_security_group.default.arn,
        id   = aws_default_security_group.default.id,
        name = aws_default_security_group.default.name,
      }
    }
    aws_security_group = {
      internal_traffic = {
        arn  = aws_security_group.internal_traffic.arn,
        id   = aws_security_group.internal_traffic.id,
        name = aws_security_group.internal_traffic.name,
      }
    }
  }
}
