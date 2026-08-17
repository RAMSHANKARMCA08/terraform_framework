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

module "router" {
  source = "../../../cloud/aws/modules/cloudfront-path-router"

  environment         = var.environment
  domain_name         = var.domain_name
  default_application = var.default_application
  routes = {
    instant-app = {
      origin_domain_name = "origin-instant-app.${var.domain_name}"
      origin_protocol    = "https-only"
    }
    myk8sapp = {
      origin_domain_name = "origin-myk8sapp.${var.domain_name}"
      origin_http_port   = 30080
      origin_protocol    = "http-only"
    }
  }
  tags = local.tags
}

module "budget" {
  source = "../../../cloud/aws/modules/budget"

  application       = var.application
  environment       = var.environment
  monthly_limit_usd = var.monthly_budget_usd
  tags              = local.tags
}
