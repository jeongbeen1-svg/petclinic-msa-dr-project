locals {
  namespace = var.namespace
  location  = var.location

  common_tags = {
    Environment = "dev"
    Project     = "Project3-MSA"
    ManagedBy   = "Terraform"
  }

  vnet = {
    name          = "main"
    address_space = "10.0.0.0/16"
  }

  subnet_public = [
    {
      name         = "public-a"
      address_cidr = "10.0.1.0/24"
    },
    {
      name         = "public-b"
      address_cidr = "10.0.2.0/24"
    }
  ]

  subnet_private = [
    {
      name         = "private-a"
      address_cidr = "10.0.101.0/24"
    },
    {
      name         = "private-b"
      address_cidr = "10.0.102.0/24"
    }
  ]

  natgw = {
    name = "main"
  }
}
