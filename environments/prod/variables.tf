variable "project" {
  description = "Project name used for naming resources."
  type        = string
}

variable "owner" {
  description = "Owner tag value."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones used by VPC and EKS."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Whether to use a single shared NAT gateway."
  type        = bool
  default     = true
}

variable "cluster_api_ingress_cidrs" {
  description = "Trusted CIDRs that can access the EKS API security group."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "endpoint_private_access" {
  description = "Enable private endpoint access for EKS API."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public endpoint access for EKS API."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "Public CIDRs allowed to access EKS API endpoint."
  type        = list(string)
  default     = []
}

variable "authentication_mode" {
  description = "Authentication mode for EKS access entries."
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Whether to bootstrap cluster creator as admin."
  type        = bool
  default     = false
}

variable "enabled_cluster_log_types" {
  description = "Enabled EKS control-plane logs."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days for EKS logs."
  type        = number
  default     = 30
}

variable "node_groups" {
  description = "Map of managed node-group configuration."
  type = map(object({
    instance_types                 = list(string)
    capacity_type                  = string
    desired_size                   = number
    max_size                       = number
    min_size                       = number
    disk_size                      = number
    ami_type                       = string
    labels                         = map(string)
    taints                         = list(object({ key = string, value = string, effect = string }))
    max_unavailable_percentage     = number
    additional_managed_policy_arns = list(string)
  }))
}

variable "ecr_repository_names" {
  description = "List of ECR repositories to create."
  type        = list(string)
  default     = []
}

variable "ecr_encryption_type" {
  description = "ECR encryption type (AES256 or KMS)."
  type        = string
  default     = "AES256"
}

variable "ecr_kms_key_arn" {
  description = "Optional KMS key ARN for ECR encryption type KMS."
  type        = string
  default     = null
}

variable "irsa_roles" {
  description = "Additional IRSA roles for workloads."
  type = map(object({
    namespace            = string
    service_account_name = string
    managed_policy_arns  = list(string)
    inline_policy_json   = optional(string)
  }))
  default = {}
}

variable "enable_kubernetes_providers" {
  description = "Enable kubernetes and helm providers (set true after EKS exists)."
  type        = bool
  default     = false
}

variable "enable_alb_controller" {
  description = "Install AWS Load Balancer Controller via Helm."
  type        = bool
  default     = false
}

variable "alb_controller_chart_version" {
  description = "Helm chart version for AWS Load Balancer Controller."
  type        = string
  default     = "1.11.0"
}

variable "enable_applications" {
  description = "Deploy application Kubernetes resources."
  type        = bool
  default     = false
}

variable "selected_apps" {
  description = "Optional subset of applications to deploy. Empty means all."
  type        = list(string)
  default     = []
}

variable "application_defaults" {
  description = "Default configuration for all applications."
  type = map(object({
    namespace        = string
    image_repository = string
    image_tag        = string
    replicas         = number
    container_port   = number
    service_port     = number
    service_type     = string
    resources = object({
      requests = map(string)
      limits   = map(string)
    })
    env_vars = map(string)
    secret_env_vars = list(object({
      name        = string
      secret_name = string
      secret_key  = string
      optional    = bool
    }))
    config_map_data     = map(string)
    enable_ingress      = bool
    ingress_host        = string
    ingress_annotations = map(string)
    hpa = object({
      enabled                           = bool
      min_replicas                      = number
      max_replicas                      = number
      target_cpu_utilization_percentage = number
    })
    pdb = object({
      enabled       = bool
      min_available = string
    })
    labels = map(string)
    liveness_probe = object({
      path                  = string
      port                  = number
      initial_delay_seconds = number
      period_seconds        = number
      timeout_seconds       = number
      failure_threshold     = number
    })
    readiness_probe = object({
      path                  = string
      port                  = number
      initial_delay_seconds = number
      period_seconds        = number
      timeout_seconds       = number
      failure_threshold     = number
    })
    topology_spread_constraints = list(object({
      max_skew           = number
      topology_key       = string
      when_unsatisfiable = string
    }))
  }))
}

variable "application_overrides" {
  description = "Environment or app-specific overrides merged on top of defaults."
  type = map(object({
    namespace        = string
    image_repository = string
    image_tag        = string
    replicas         = number
    container_port   = number
    service_port     = number
    service_type     = string
    resources = object({
      requests = map(string)
      limits   = map(string)
    })
    env_vars = map(string)
    secret_env_vars = list(object({
      name        = string
      secret_name = string
      secret_key  = string
      optional    = bool
    }))
    config_map_data     = map(string)
    enable_ingress      = bool
    ingress_host        = string
    ingress_annotations = map(string)
    hpa = object({
      enabled                           = bool
      min_replicas                      = number
      max_replicas                      = number
      target_cpu_utilization_percentage = number
    })
    pdb = object({
      enabled       = bool
      min_available = string
    })
    labels = map(string)
    liveness_probe = object({
      path                  = string
      port                  = number
      initial_delay_seconds = number
      period_seconds        = number
      timeout_seconds       = number
      failure_threshold     = number
    })
    readiness_probe = object({
      path                  = string
      port                  = number
      initial_delay_seconds = number
      period_seconds        = number
      timeout_seconds       = number
      failure_threshold     = number
    })
    topology_spread_constraints = list(object({
      max_skew           = number
      topology_key       = string
      when_unsatisfiable = string
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Additional common tags."
  type        = map(string)
  default     = {}
}
variable "enable_cluster_autoscaler" {
  type    = bool
  default = true
}

variable "cluster_autoscaler_chart_version" {
  type    = string
  default = "9.46.6"
}

variable "enable_external_dns" {
  type    = bool
  default = false
}

variable "external_dns_chart_version" {
  type    = string
  default = "1.15.2"
}

variable "route53_domain_name" {
  type    = string
  default = ""
}

variable "create_route53_zone" {
  type    = bool
  default = false
}

variable "enable_waf" {
  type    = bool
  default = false
}

variable "enable_vpc_endpoints" {
  description = "Create private VPC endpoints for AWS services."
  type        = bool
  default     = true
}

variable "vpc_gateway_endpoint_services" {
  description = "Gateway endpoint service names."
  type        = list(string)
  default     = ["s3"]
}

variable "vpc_interface_endpoint_services" {
  description = "Interface endpoint service names."
  type        = list(string)
  default     = ["ecr.api", "ecr.dkr", "sts", "logs", "ec2", "autoscaling"]
}
