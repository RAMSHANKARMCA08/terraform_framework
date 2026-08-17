project     = "eks-platform"
owner       = "platform-team"
environment = "dev"
aws_region  = "us-east-1"

cluster_name       = "eks-platform-dev"
kubernetes_version = "1.31"

vpc_cidr             = "10.10.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]

single_nat_gateway        = true
cluster_api_ingress_cidrs = ["10.0.0.0/8"]
endpoint_private_access   = true
endpoint_public_access    = false
public_access_cidrs       = []

enabled_cluster_log_types = ["api", "audit", "authenticator"]
log_retention_days        = 14

node_groups = {
  general = {
    instance_types                 = ["t3.large"]
    capacity_type                  = "ON_DEMAND"
    desired_size                   = 2
    max_size                       = 4
    min_size                       = 2
    disk_size                      = 50
    ami_type                       = "AL2_x86_64"
    labels                         = { workload = "general" }
    taints                         = []
    max_unavailable_percentage     = 33
    additional_managed_policy_arns = []
  }
}

enable_kubernetes_providers = false
enable_alb_controller       = false
enable_applications         = false
application_defaults        = {}

tags = {
  CostCenter = "platform"
}

enable_cluster_autoscaler = true
enable_external_dns       = false
enable_waf                = false
