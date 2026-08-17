variable "name_prefix" { type = string }
variable "region_label" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "certificate_arn" { type = string }
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "key_name" {
  description = "Existing regional EC2 key pair name used by application instances."
  type        = string
}
variable "desired_capacity" {
  type    = number
  default = 1
}
variable "min_size" {
  type    = number
  default = 1
}
variable "max_size" {
  type    = number
  default = 2
}
variable "tags" {
  type    = map(string)
  default = {}
}
