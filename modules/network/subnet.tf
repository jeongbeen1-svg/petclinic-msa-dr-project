# public subnet 0
resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnet_public[0].cidr_block
  availability_zone       = local.subnet_public[0].availability_zone
  map_public_ip_on_launch = local.subnet_public[0].map_public_ip_on_launch

  tags = {
    Name = "${local.namespace}-subnet-${local.subnet_public[0].name}"
  }
}

# public subnet 1
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnet_public[1].cidr_block
  availability_zone       = local.subnet_public[1].availability_zone
  map_public_ip_on_launch = local.subnet_public[1].map_public_ip_on_launch

  tags = {
    Name = "${local.namespace}-subnet-${local.subnet_public[1].name}"
  }
}

# private subnet_0
resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnet_private[0].cidr_block
  availability_zone       = local.subnet_private[0].availability_zone
  map_public_ip_on_launch = local.subnet_private[0].map_public_ip_on_launch

  tags = {
    Name = "${local.namespace}-subnet-${local.subnet_private[0].name}"
  }
}

# private subnet_1
resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnet_private[1].cidr_block
  availability_zone       = local.subnet_private[1].availability_zone
  map_public_ip_on_launch = local.subnet_private[1].map_public_ip_on_launch

  tags = {
    Name = "${local.namespace}-subnet-${local.subnet_private[1].name}"
  }
}

resource "aws_route_table" "public_0" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.namespace}-rtb-${local.subnet_public[0].name}"
  }
}

resource "aws_route_table" "public_1" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.namespace}-rtb-${local.subnet_public[1].name}"
  }
}

resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${local.namespace}-rtb-${local.subnet_private[0].name}"
  }
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${local.namespace}-rtb-${local.subnet_private[1].name}"
  }
}

resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public_0.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_1.id
}

resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}