application   = "instant-app"
environment   = "prod"
owner         = "platform-team"
domain_name   = "ramdevops.site"
instance_type = "t3.micro"
key_name      = "ramkey2026"
use_autoscaling = false

mumbai_availability_zones   = ["ap-south-1a", "ap-south-1b"]
mumbai_vpc_cidr             = "10.31.0.0/16"
mumbai_public_subnet_cidrs  = ["10.31.0.0/24", "10.31.1.0/24"]
mumbai_private_subnet_cidrs = ["10.31.10.0/24", "10.31.11.0/24"]

sydney_availability_zones   = ["ap-southeast-2a", "ap-southeast-2b"]
sydney_vpc_cidr             = "10.32.0.0/16"
sydney_public_subnet_cidrs  = ["10.32.0.0/24", "10.32.1.0/24"]
sydney_private_subnet_cidrs = ["10.32.10.0/24", "10.32.11.0/24"]

tags = { CostCenter = "instant-app" }
