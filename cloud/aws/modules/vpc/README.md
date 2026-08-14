# VPC Module

Reusable VPC module for EKS-oriented networking.

## Features
- Multi-AZ public and private subnets
- Internet gateway and route tables
- NAT gateways (single or per-AZ)
- EKS-compatible subnet tags

## Usage
```hcl
module "vpc" {
  source               = "../../modules/vpc"
  name_prefix          = "eks-platform-dev"
  cluster_name         = "eks-platform-dev"
  vpc_cidr             = "10.10.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
  private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]
  single_nat_gateway   = true
  tags                 = local.tags
}
```
