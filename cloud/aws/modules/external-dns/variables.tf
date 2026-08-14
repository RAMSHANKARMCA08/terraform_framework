variable "name_prefix" {
  type = string
}
variable "cluster_name" {
  type = string
}
variable "domain_name" {
  type = string
}
variable "hosted_zone_id" {
  type = string
}
variable "oidc_provider_arn" {
  type = string
}
variable "oidc_provider_url" {
  type = string
}
variable "chart_version" {
  type = string
}
variable "namespace" {
  type    = string
  default = "kube-system"
}
variable "service_account_name" {
  type    = string
  default = "external-dns"
}
variable "tags" {
  type    = map(string)
  default = {}
}

