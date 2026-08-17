variable "environment" { type = string }
variable "domain_name" { type = string }
variable "default_application" { type = string }
variable "routes" {
  type = map(object({
    origin_domain_name = string
    origin_http_port   = optional(number, 80)
    origin_https_port  = optional(number, 443)
    origin_protocol    = optional(string, "https-only")
  }))
  validation {
    condition     = alltrue([for route in values(var.routes) : contains(["http-only", "https-only", "match-viewer"], route.origin_protocol)])
    error_message = "origin_protocol must be http-only, https-only, or match-viewer."
  }
}
variable "price_class" {
  type    = string
  default = "PriceClass_200"
}
variable "tags" {
  type    = map(string)
  default = {}
}
