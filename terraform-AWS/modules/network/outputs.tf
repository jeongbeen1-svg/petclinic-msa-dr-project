output "vpc" {
  value = {
    (local.vpc.name) = {
      id = aws_vpc.this.id
    }
  }
}

output "subnet" {
  value = {
    (local.subnet_public[0].name) = {
      id         = aws_subnet.public_0.id
      cidr_block = aws_subnet.public_0.cidr_block
    }
    (local.subnet_public[1].name) = {
      id         = aws_subnet.public_1.id
      cidr_block = aws_subnet.public_1.cidr_block
    }
    (local.subnet_private[0].name) = {
      id         = aws_subnet.private_0.id
      cidr_block = aws_subnet.private_0.cidr_block
    }
    (local.subnet_private[1].name) = {
      id         = aws_subnet.private_1.id
      cidr_block = aws_subnet.private_1.cidr_block
    }
    (local.subnet_private[2].name) = {
      id         = aws_subnet.private_2.id
      cidr_block = aws_subnet.private_2.cidr_block
    }
    (local.subnet_private[3].name) = {
      id         = aws_subnet.private_3.id
      cidr_block = aws_subnet.private_3.cidr_block
    }
    (local.subnet_private[4].name) = {
      id         = aws_subnet.private_4.id
      cidr_block = aws_subnet.private_4.cidr_block
    }
    (local.subnet_private[5].name) = {
      id         = aws_subnet.private_5.id
      cidr_block = aws_subnet.private_5.cidr_block
    }
  }
}