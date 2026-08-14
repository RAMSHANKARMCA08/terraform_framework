variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by EKS control plane and nodes."
  type        = list(string)
}

variable "additional_security_group_ids" {
  description = "Additional security groups attached to EKS control plane."
  type        = list(string)
  default     = []
}

variable "endpoint_private_access" {
  description = "Enable private endpoint access."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public endpoint access."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "Allowed CIDRs for public endpoint access."
  type        = list(string)
  default     = []
}

variable "authentication_mode" {
  description = "EKS cluster authentication mode."
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Grant cluster creator admin permissions."
  type        = bool
  default     = false
}

variable "enabled_cluster_log_types" {
  description = "Enabled EKS control plane log types."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention for EKS control plane logs."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
