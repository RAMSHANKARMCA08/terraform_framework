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
variable "use_autoscaling" {
  description = "Use an Auto Scaling Group instead of one directly managed EC2 instance."
  type        = bool
  default     = true
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
  default = 1
}
variable "tags" {
  type    = map(string)
  default = {}
}
