variable "name_prefix" {
  description = "Name prefix for resources."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID used by the cluster."
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN from EKS module."
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL from EKS module."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the controller."
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Kubernetes service account name for the controller."
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "chart_version" {
  description = "Helm chart version for AWS Load Balancer Controller."
  type        = string
  default     = "1.11.0"
}

variable "policy_json" {
  description = "IAM policy JSON document used by the controller role."
  type        = string
  sensitive   = false
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
