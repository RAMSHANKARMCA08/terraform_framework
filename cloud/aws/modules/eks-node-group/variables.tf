variable "name_prefix" {
  description = "Name prefix for node-group resources."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "node_group_name" {
  description = "Logical node-group name."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where nodes run."
  type        = list(string)
}

variable "instance_types" {
  description = "EC2 instance types for the node group."
  type        = list(string)
}

variable "capacity_type" {
  description = "Node group capacity type: ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "desired_size" {
  description = "Desired number of nodes."
  type        = number
}

variable "max_size" {
  description = "Maximum number of nodes."
  type        = number
}

variable "min_size" {
  description = "Minimum number of nodes."
  type        = number
}

variable "disk_size" {
  description = "Node root volume size in GiB."
  type        = number
  default     = 50
}

variable "ami_type" {
  description = "EKS node AMI type."
  type        = string
  default     = "AL2_x86_64"
}

variable "labels" {
  description = "Kubernetes labels for the node group."
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = "Kubernetes taints for the node group."
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "max_unavailable_percentage" {
  description = "Max unavailable percentage during rolling update."
  type        = number
  default     = 33
}

variable "additional_managed_policy_arns" {
  description = "Additional managed IAM policy ARNs for node IAM role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
