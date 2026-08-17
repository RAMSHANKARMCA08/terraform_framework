locals {
  tags = merge({
    Application = var.application
    Project     = var.application
    Environment = var.environment
    env         = var.environment
    projectname = var.application
    ManagedBy   = "terraform"
    Owner       = var.owner
  }, var.tags)
}

module "application" {
  source = "../../../cloud/aws/modules/multi-region-alb-app"
  providers = {
    aws.mumbai = aws.mumbai
    aws.sydney = aws.sydney
  }

  application                 = var.application
  environment                 = var.environment
  owner                       = var.owner
  domain_name                 = var.domain_name
  mumbai_region               = var.mumbai_region
  sydney_region               = var.sydney_region
  mumbai_availability_zones   = var.mumbai_availability_zones
  sydney_availability_zones   = var.sydney_availability_zones
  mumbai_vpc_cidr             = var.mumbai_vpc_cidr
  sydney_vpc_cidr             = var.sydney_vpc_cidr
  mumbai_public_subnet_cidrs  = var.mumbai_public_subnet_cidrs
  mumbai_private_subnet_cidrs = var.mumbai_private_subnet_cidrs
  sydney_public_subnet_cidrs  = var.sydney_public_subnet_cidrs
  sydney_private_subnet_cidrs = var.sydney_private_subnet_cidrs
  instance_type               = var.instance_type
  key_name                    = var.key_name
  tags                        = var.tags
}
