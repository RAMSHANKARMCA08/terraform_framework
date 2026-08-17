variable "application" {
  type    = string
  default = "shared-routing"
}
variable "environment" {
  type    = string
  default = "prod"
}
variable "owner" {
  type    = string
  default = "platform-team"
}
variable "domain_name" {
  type    = string
  default = "ramdevops.site"
}
variable "default_application" {
  type    = string
  default = "instant-app"
}
variable "monthly_budget_usd" {
  type    = number
  default = 10
}
variable "tags" {
  type    = map(string)
  default = {}
}
