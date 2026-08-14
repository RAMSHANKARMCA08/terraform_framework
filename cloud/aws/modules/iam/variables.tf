variable "name_prefix" {
  description = "Name prefix for IAM resources."
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

variable "irsa_roles" {
  description = "Map of IRSA roles to create."
  type = map(object({
    namespace            = string
    service_account_name = string
    managed_policy_arns  = list(string)
    inline_policy_json   = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
