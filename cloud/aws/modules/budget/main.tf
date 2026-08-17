resource "aws_budgets_budget" "this" {
  name         = "${var.application}-${var.environment}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  cost_filter {
    name   = "TagKeyValue"
    values = [format("user:projectname$%s", var.application)]
  }
  tags = var.tags
}
