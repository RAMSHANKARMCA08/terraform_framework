terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [aws.mumbai, aws.sydney]
    }
  }
}

locals {
  name_prefix = "${var.application}-${var.environment}"
  tags = merge({
    Application = var.application
    Project     = var.application
    Environment = var.environment
    env         = var.environment
    projectname = var.application
    ManagedBy   = "terraform"
    Owner       = var.owner
  }, var.tags)
  main_hostname    = "${var.application}.${var.domain_name}"
  mumbai_hostname  = "mumbai-${var.application}.${var.domain_name}"
  sydney_hostname  = "sydney-${var.application}.${var.domain_name}"
}

data "aws_route53_zone" "existing" {
  provider     = aws.mumbai
  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "mumbai" {
  provider          = aws.mumbai
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
  tags = local.tags
}

resource "aws_acm_certificate" "sydney" {
  provider          = aws.sydney
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
  tags = local.tags
}

resource "aws_route53_record" "certificate_validation" {
  provider        = aws.mumbai
  zone_id         = data.aws_route53_zone.existing.zone_id
  name            = one(aws_acm_certificate.mumbai.domain_validation_options).resource_record_name
  type            = one(aws_acm_certificate.mumbai.domain_validation_options).resource_record_type
  records         = [one(aws_acm_certificate.mumbai.domain_validation_options).resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "mumbai" {
  provider                = aws.mumbai
  certificate_arn         = aws_acm_certificate.mumbai.arn
  validation_record_fqdns = [aws_route53_record.certificate_validation.fqdn]
}

resource "aws_acm_certificate_validation" "sydney" {
  provider                = aws.sydney
  certificate_arn         = aws_acm_certificate.sydney.arn
  validation_record_fqdns = [aws_route53_record.certificate_validation.fqdn]
}

module "mumbai_vpc" {
  source               = "../vpc"
  providers            = { aws = aws.mumbai }
  name_prefix          = "${local.name_prefix}-mumbai"
  cluster_name         = local.name_prefix
  vpc_cidr             = var.mumbai_vpc_cidr
  availability_zones   = var.mumbai_availability_zones
  public_subnet_cidrs  = var.mumbai_public_subnet_cidrs
  private_subnet_cidrs = var.mumbai_private_subnet_cidrs
  single_nat_gateway   = true
  tags                 = local.tags
}

module "sydney_vpc" {
  source               = "../vpc"
  providers            = { aws = aws.sydney }
  name_prefix          = "${local.name_prefix}-sydney"
  cluster_name         = local.name_prefix
  vpc_cidr             = var.sydney_vpc_cidr
  availability_zones   = var.sydney_availability_zones
  public_subnet_cidrs  = var.sydney_public_subnet_cidrs
  private_subnet_cidrs = var.sydney_private_subnet_cidrs
  single_nat_gateway   = true
  tags                 = local.tags
}

module "mumbai_application" {
  source             = "../regional-alb-app"
  providers          = { aws = aws.mumbai }
  name_prefix        = local.name_prefix
  region_label       = "mumbai"
  vpc_id             = module.mumbai_vpc.vpc_id
  vpc_cidr           = var.mumbai_vpc_cidr
  public_subnet_ids  = module.mumbai_vpc.public_subnet_ids
  private_subnet_ids = module.mumbai_vpc.private_subnet_ids
  certificate_arn    = aws_acm_certificate_validation.mumbai.certificate_arn
  instance_type      = var.instance_type
  key_name           = var.key_name
  tags               = local.tags
}

module "sydney_application" {
  source             = "../regional-alb-app"
  providers          = { aws = aws.sydney }
  name_prefix        = local.name_prefix
  region_label       = "sydney"
  vpc_id             = module.sydney_vpc.vpc_id
  vpc_cidr           = var.sydney_vpc_cidr
  public_subnet_ids  = module.sydney_vpc.public_subnet_ids
  private_subnet_ids = module.sydney_vpc.private_subnet_ids
  certificate_arn    = aws_acm_certificate_validation.sydney.certificate_arn
  instance_type      = var.instance_type
  key_name           = var.key_name
  tags               = local.tags
}

resource "aws_route53_record" "main_primary" {
  provider       = aws.mumbai
  zone_id        = data.aws_route53_zone.existing.zone_id
  name           = local.main_hostname
  type           = "A"
  set_identifier = "mumbai-primary"
  failover_routing_policy { type = "PRIMARY" }
  alias {
    name                   = module.mumbai_application.alb_dns_name
    zone_id                = module.mumbai_application.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "main_secondary" {
  provider       = aws.mumbai
  zone_id        = data.aws_route53_zone.existing.zone_id
  name           = local.main_hostname
  type           = "A"
  set_identifier = "sydney-secondary"
  failover_routing_policy { type = "SECONDARY" }
  alias {
    name                   = module.sydney_application.alb_dns_name
    zone_id                = module.sydney_application.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "mumbai_direct" {
  provider = aws.mumbai
  zone_id  = data.aws_route53_zone.existing.zone_id
  name     = local.mumbai_hostname
  type     = "A"
  alias {
    name                   = module.mumbai_application.alb_dns_name
    zone_id                = module.mumbai_application.alb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "sydney_direct" {
  provider = aws.mumbai
  zone_id  = data.aws_route53_zone.existing.zone_id
  name     = local.sydney_hostname
  type     = "A"
  alias {
    name                   = module.sydney_application.alb_dns_name
    zone_id                = module.sydney_application.alb_zone_id
    evaluate_target_health = false
  }
}
