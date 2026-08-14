locals {
  name_prefix = "${var.project}-${var.environment}"
  tags = merge({
    Project = var.project, Environment = var.environment, ManagedBy = "terraform", Owner = var.owner
  }, var.tags)
}

module "vpc" {
  source               = "../../cloud/aws/modules/vpc"
  name_prefix          = local.name_prefix
  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
  tags                 = local.tags
}

module "cluster_access_sg" {
  source              = "../../cloud/aws/modules/security-groups"
  name_prefix         = local.name_prefix
  security_group_name = "cluster-access"
  description         = "Ingress to EKS control plane from trusted CIDRs"
  vpc_id              = module.vpc.vpc_id
  ingress_rules       = [for cidr in var.cluster_api_ingress_cidrs : { protocol = "tcp", from_port = 443, to_port = 443, cidr_ipv4 = cidr, description = "Allow EKS API access" }]
  tags                = local.tags
}

module "eks" {
  source                                      = "../../cloud/aws/modules/eks"
  cluster_name                                = var.cluster_name
  kubernetes_version                          = var.kubernetes_version
  vpc_id                                      = module.vpc.vpc_id
  private_subnet_ids                          = module.vpc.private_subnet_ids
  additional_security_group_ids               = [module.cluster_access_sg.security_group_id]
  endpoint_private_access                     = var.endpoint_private_access
  endpoint_public_access                      = var.endpoint_public_access
  public_access_cidrs                         = var.public_access_cidrs
  authentication_mode                         = var.authentication_mode
  bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  enabled_cluster_log_types                   = var.enabled_cluster_log_types
  log_retention_days                          = var.log_retention_days
  tags                                        = local.tags
}

module "node_groups" {
  source                         = "../../cloud/aws/modules/eks-node-group"
  for_each                       = var.node_groups
  name_prefix                    = local.name_prefix
  cluster_name                   = module.eks.cluster_name
  node_group_name                = each.key
  private_subnet_ids             = module.vpc.private_subnet_ids
  instance_types                 = each.value.instance_types
  capacity_type                  = each.value.capacity_type
  desired_size                   = each.value.desired_size
  max_size                       = each.value.max_size
  min_size                       = each.value.min_size
  disk_size                      = each.value.disk_size
  ami_type                       = each.value.ami_type
  labels                         = merge(each.value.labels, { env = var.environment, projectname = var.project })
  taints                         = each.value.taints
  max_unavailable_percentage     = each.value.max_unavailable_percentage
  additional_managed_policy_arns = each.value.additional_managed_policy_arns
  tags                           = local.tags
}

module "ecr" {
  source           = "../../cloud/aws/modules/ecr"
  name_prefix      = local.name_prefix
  repository_names = var.ecr_repository_names
  encryption_type  = var.ecr_encryption_type
  kms_key_arn      = var.ecr_kms_key_arn
  tags             = local.tags
}

module "iam" {
  source            = "../../cloud/aws/modules/iam"
  name_prefix       = local.name_prefix
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_issuer_url
  irsa_roles        = var.irsa_roles
  tags              = local.tags
}

module "vpc_endpoints" {
  source = "../../cloud/aws/modules/vpc-endpoints"
  count  = var.enable_vpc_endpoints ? 1 : 0

  name_prefix        = local.name_prefix
  region             = var.aws_region
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  route_table_ids    = module.vpc.private_route_table_ids
  allowed_cidrs      = [var.vpc_cidr]
  gateway_services   = var.vpc_gateway_endpoint_services
  interface_services = var.vpc_interface_endpoint_services
  tags               = local.tags
}
