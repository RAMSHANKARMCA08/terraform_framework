resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-${var.security_group_name}"
  description = var.description
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${var.security_group_name}"
  })
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = {
    for idx, rule in var.ingress_rules : idx => rule
  }

  security_group_id = aws_security_group.this.id
  ip_protocol       = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_ipv4         = each.value.cidr_ipv4
  description       = each.value.description
}

resource "aws_vpc_security_group_ingress_rule" "source_security_group" {
  for_each = {
    for idx, rule in var.ingress_security_group_rules : idx => rule
  }

  security_group_id            = aws_security_group.this.id
  ip_protocol                  = each.value.protocol
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  referenced_security_group_id = each.value.referenced_security_group_id
  description                  = each.value.description
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = {
    for idx, rule in var.egress_rules : idx => rule
  }

  security_group_id = aws_security_group.this.id
  ip_protocol       = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_ipv4         = each.value.cidr_ipv4
  description       = each.value.description
}
