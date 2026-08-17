locals {
  name_prefix = "${var.application}-${var.environment}"
  tags = merge({
    Application = var.application
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
    env         = var.environment
    projectname = var.application
  }, var.tags)
}

module "vpc" {
  source               = "../../../cloud/aws/modules/vpc"
  name_prefix          = local.name_prefix
  cluster_name         = local.name_prefix
  vpc_cidr             = "10.41.0.0/16"
  availability_zones   = ["ap-south-1a", "ap-south-1b"]
  public_subnet_cidrs  = ["10.41.0.0/24", "10.41.1.0/24"]
  private_subnet_cidrs = ["10.41.10.0/24", "10.41.11.0/24"]
  create_nat_gateway   = false
  tags                 = local.tags
}

module "eks" {
  source                                      = "../../../cloud/aws/modules/eks"
  cluster_name                                = local.name_prefix
  kubernetes_version                          = var.kubernetes_version
  vpc_id                                      = module.vpc.vpc_id
  private_subnet_ids                          = module.vpc.public_subnet_ids
  endpoint_private_access                     = false
  endpoint_public_access                      = true
  public_access_cidrs                         = ["0.0.0.0/0"]
  bootstrap_cluster_creator_admin_permissions = true
  enabled_cluster_log_types                   = []
  log_retention_days                          = 1
  tags                                        = local.tags
}

module "worker" {
  source                     = "../../../cloud/aws/modules/eks-node-group"
  name_prefix                = local.name_prefix
  cluster_name               = module.eks.cluster_name
  node_group_name            = "worker"
  private_subnet_ids         = module.vpc.public_subnet_ids
  instance_types             = [var.instance_type]
  capacity_type              = "ON_DEMAND"
  desired_size               = 1
  min_size                   = 1
  max_size                   = 1
  disk_size                  = 20
  ami_type                   = "AL2023_x86_64_STANDARD"
  labels                     = { workload = var.application }
  taints                     = []
  max_unavailable_percentage = 100
  tags                       = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "public_http" {
  security_group_id = module.eks.managed_cluster_security_group_id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Temporary public HTTP test access"
}

resource "aws_vpc_security_group_ingress_rule" "node_port" {
  security_group_id = module.eks.managed_cluster_security_group_id
  ip_protocol       = "tcp"
  from_port         = 30080
  to_port           = 30080
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Temporary public NodePort test access"
}

resource "kubernetes_namespace" "this" {
  metadata {
    name   = var.application
    labels = { env = var.environment, projectname = var.application }
  }
  depends_on = [module.worker]
}

resource "kubernetes_deployment" "this" {
  metadata {
    name      = var.application
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = var.application }
    }
    template {
      metadata {
        labels = { app = var.application, env = var.environment, projectname = var.application }
      }
      spec {
        container {
          name  = var.application
          image = "nginx:1.27-alpine"
          port {
            container_port = 80
            host_port      = 80
          }
          resources {
            requests = { cpu = "25m", memory = "32Mi" }
            limits   = { cpu = "100m", memory = "64Mi" }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "this" {
  metadata {
    name      = var.application
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  spec {
    selector = { app = var.application }
    port {
      port        = 80
      target_port = 80
      node_port   = 30080
    }
    type = "NodePort"
  }
}

data "aws_instances" "worker" {
  filter {
    name   = "tag:eks:cluster-name"
    values = [module.eks.cluster_name]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
  depends_on = [module.worker]
}

data "aws_route53_zone" "existing" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "application" {
  zone_id = data.aws_route53_zone.existing.zone_id
  name    = "origin-${var.application}.${var.domain_name}"
  type    = "A"
  ttl     = 60
  records = [one(data.aws_instances.worker.public_ips)]
}
