variable "name_prefix" {
  description = "Name prefix for SG resources."
  type        = string
}

variable "security_group_name" {
  description = "Security group name suffix."
  type        = string
}

variable "description" {
  description = "Security group description."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "ingress_rules" {
  description = "List of ingress rules."
  type = list(object({
    protocol    = string
    from_port   = number
    to_port     = number
    cidr_ipv4   = string
    description = string
  }))
  default = []
}

variable "ingress_security_group_rules" {
  description = "Ingress rules whose source is another security group."
  type = list(object({
    protocol                     = string
    from_port                    = number
    to_port                      = number
    referenced_security_group_id = string
    description                  = string
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rules."
  type = list(object({
    protocol    = string
    from_port   = number
    to_port     = number
    cidr_ipv4   = string
    description = string
  }))
  default = [{
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_ipv4   = "0.0.0.0/0"
    description = "Allow all outbound traffic"
  }]
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
