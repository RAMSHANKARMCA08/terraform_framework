variable "name_prefix" {
  type = string
}
variable "managed_rule_groups" {
  type = list(object({
    name        = string
    vendor_name = string
  }))
  default = [
    { name = "AWSManagedRulesCommonRuleSet", vendor_name = "AWS" },
    { name = "AWSManagedRulesKnownBadInputsRuleSet", vendor_name = "AWS" }
  ]
}
variable "tags" {
  type    = map(string)
  default = {}
}

