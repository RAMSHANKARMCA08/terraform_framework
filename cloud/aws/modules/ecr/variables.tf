variable "name_prefix" {
  description = "Name prefix used for tagging and naming conventions."
  type        = string
}

variable "repository_names" {
  description = "List of ECR repositories to create."
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "ECR image tag mutability setting."
  type        = string
  default     = "IMMUTABLE"
}

variable "encryption_type" {
  description = "ECR encryption type (AES256 or KMS)."
  type        = string
  default     = "AES256"
}

variable "kms_key_arn" {
  description = "KMS key ARN for ECR encryption when using KMS encryption type."
  type        = string
  default     = null
}

variable "tagged_image_retention_count" {
  description = "Max number of tagged images to keep."
  type        = number
  default     = 30
}

variable "untagged_image_retention_count" {
  description = "Max number of untagged images to keep."
  type        = number
  default     = 5
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
