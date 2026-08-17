variable "application" { type = string }
variable "environment" { type = string }
variable "owner" { type = string }
variable "domain_name" { type = string }
variable "mumbai_region" { type = string }
variable "sydney_region" { type = string }
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
variable "key_name" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
