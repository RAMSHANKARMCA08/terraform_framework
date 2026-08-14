locals {
  interface_services = toset(var.interface_services)
}

resource "aws_vpc_endpoint" "gateway" {
  for_each = toset(var.gateway_services)

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids
  tags              = merge(var.tags, { Name = "${var.name_prefix}-${each.value}-endpoint" })
}

resource "aws_security_group" "endpoints" {
  count = length(local.interface_services) > 0 ? 1 : 0

  name        = "${var.name_prefix}-vpc-endpoints"
  description = "HTTPS access to interface VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-vpc-endpoints" })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_services

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.endpoints[0].id]
  private_dns_enabled = true
  tags                = merge(var.tags, { Name = "${var.name_prefix}-${each.value}-endpoint" })
}

