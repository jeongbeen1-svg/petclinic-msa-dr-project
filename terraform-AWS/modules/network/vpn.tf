resource "aws_customer_gateway" "azure" {
  count = var.azure_customer_gateway_ip_address != null ? 1 : 0

  bgp_asn    = 65000
  ip_address = var.azure_customer_gateway_ip_address
  type       = "ipsec.1"

  tags = {
    Name = "custom-gw"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpn_gateway" "azure" {
  count = var.azure_customer_gateway_ip_address != null ? 1 : 0

  vpc_id          = aws_vpc.this.id
  amazon_side_asn = 64512

  tags = {
    Name = "virtual-private-gw"
  }
}

resource "aws_vpn_connection" "azure" {
  count = var.azure_customer_gateway_ip_address != null ? 1 : 0

  customer_gateway_id = aws_customer_gateway.azure[0].id
  vpn_gateway_id      = aws_vpn_gateway.azure[0].id
  type                = "ipsec.1"
  static_routes_only  = true

  tunnel1_inside_cidr   = "169.254.149.196/30"
  tunnel1_preshared_key = var.azure_vpn_tunnel1_preshared_key
  tunnel2_inside_cidr   = "169.254.90.104/30"
  tunnel2_preshared_key = var.azure_vpn_tunnel2_preshared_key

  tags = {
    Name = "vpn-dms"
  }
}

resource "aws_vpn_connection_route" "azure" {
  count = var.azure_vnet_cidr != null && var.azure_customer_gateway_ip_address != null ? 1 : 0

  destination_cidr_block = var.azure_vnet_cidr
  vpn_connection_id      = aws_vpn_connection.azure[0].id
}

resource "aws_route" "azure" {
  for_each = var.azure_vnet_cidr != null && var.azure_customer_gateway_ip_address != null ? {
    public-a    = aws_route_table.public_0.id
    public-c    = aws_route_table.public_1.id
    private-a   = aws_route_table.private_0.id
    private-c   = aws_route_table.private_1.id
    private-db  = aws_route_table.private_db.id
    private-dms = aws_route_table.private_dms.id
  } : {}

  route_table_id         = each.value
  destination_cidr_block = var.azure_vnet_cidr
  gateway_id             = aws_vpn_gateway.azure[0].id
}
