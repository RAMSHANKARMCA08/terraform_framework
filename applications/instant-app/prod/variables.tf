variable "application" {
  type    = string
  default = "instant-app"
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
variable "mumbai_region" {
  type    = string
  default = "ap-south-1"
}
variable "sydney_region" {
  type    = string
  default = "ap-southeast-2"
}
variable "mumbai_availability_zones" { type = list(string) }
variable "sydney_availability_zones" { type = list(string) }
variable "mumbai_vpc_cidr" { type = string }
variable "sydney_vpc_cidr" { type = string }
variable "mumbai_public_subnet_cidrs" { type = list(string) }
variable "mumbai_private_subnet_cidrs" { type = list(string) }
variable "sydney_public_subnet_cidrs" { type = list(string) }
variable "sydney_private_subnet_cidrs" { type = list(string) }
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "key_name" {
  type    = string
  default = "ramkey2026"
}
variable "use_autoscaling" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
