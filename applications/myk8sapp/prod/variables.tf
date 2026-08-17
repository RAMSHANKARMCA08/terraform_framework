variable "application" {
  type    = string
  default = "myk8sapp"
}
variable "environment" {
  type    = string
  default = "prod"
}
variable "owner" {
  type    = string
  default = "platform-team"
}
variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
variable "domain_name" {
  type    = string
  default = "ramdevops.site"
}
variable "kubernetes_version" {
  type    = string
  default = "1.33"
}
variable "instance_type" {
  type    = string
  default = "t3.small"
}
variable "tags" {
  type    = map(string)
  default = {}
}
