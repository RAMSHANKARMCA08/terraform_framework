variable "domain_name" {
  type = string
  validation {
    condition     = length(trimspace(var.domain_name)) > 0
    error_message = "domain_name must be set when Route 53 integration is enabled."
  }
}
variable "create_zone" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}

