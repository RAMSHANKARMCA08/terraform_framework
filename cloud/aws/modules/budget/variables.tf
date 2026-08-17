variable "application" { type = string }
variable "environment" { type = string }
variable "monthly_limit_usd" {
  type    = number
  default = 50
}
variable "tags" {
  type    = map(string)
  default = {}
}
