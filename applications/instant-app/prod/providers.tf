terraform {
  required_version = ">= 1.8.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.65"
    }
  }
}

provider "aws" {
  alias  = "mumbai"
  region = var.mumbai_region
  default_tags { tags = local.tags }
}

provider "aws" {
  alias  = "sydney"
  region = var.sydney_region
  default_tags { tags = local.tags }
}

provider "aws" {
  alias  = "billing"
  region = "us-east-1"
  default_tags { tags = local.tags }
}
