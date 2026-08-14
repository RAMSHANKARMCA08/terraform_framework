variable "name_prefix" { type = string }
variable "region" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "route_table_ids" { type = list(string) }
variable "allowed_cidrs" { type = list(string) }
variable "gateway_services" {
  type    = list(string)
  default = ["s3"]
}
variable "interface_services" {
  type    = list(string)
  default = ["ecr.api", "ecr.dkr", "sts", "logs", "ec2", "autoscaling"]
}
variable "tags" {
  type    = map(string)
  default = {}
}

