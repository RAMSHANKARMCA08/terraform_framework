variable "name" {
  description = "Name used for the ALB and target group."
  type        = string
}
variable "vpc_id" {
  description = "VPC containing the target group."
  type        = string
}
variable "subnet_ids" {
  description = "Subnet IDs used by the ALB."
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "An ALB requires subnets in at least two Availability Zones."
  }
}
variable "security_group_ids" {
  description = "Security groups attached to the ALB."
  type        = list(string)
}
variable "certificate_arn" {
  description = "Regional ACM certificate ARN for the HTTPS listener."
  type        = string
}
variable "internal" {
  description = "Whether the ALB is internal."
  type        = bool
  default     = false
}
variable "enable_deletion_protection" {
  description = "Protect the ALB from accidental deletion."
  type        = bool
  default     = false
}
variable "target_port" {
  type    = number
  default = 80
}
variable "target_protocol" {
  type    = string
  default = "HTTP"
}
variable "target_type" {
  type    = string
  default = "instance"
  validation {
    condition     = contains(["instance", "ip"], var.target_type)
    error_message = "target_type must be instance or ip."
  }
}
variable "health_check_path" {
  type    = string
  default = "/health"
}
variable "health_check_matcher" {
  type    = string
  default = "200"
}
variable "ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}
variable "tags" {
  type    = map(string)
  default = {}
}
