resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0

  name = var.domain_name
  tags = merge(var.tags, { Name = var.domain_name })
}

data "aws_route53_zone" "existing" {
  count = var.create_zone ? 0 : 1

  name         = var.domain_name
  private_zone = false
}

locals {
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : data.aws_route53_zone.existing[0].zone_id
}

