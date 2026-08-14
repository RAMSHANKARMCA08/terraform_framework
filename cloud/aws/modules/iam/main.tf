locals {
  oidc_provider_host = replace(var.oidc_provider_url, "https://", "")
}

resource "aws_iam_role" "irsa" {
  for_each = var.irsa_roles

  name = "${var.name_prefix}-${each.key}-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_host}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider_host}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.service_account_name}"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "irsa_managed" {
  for_each = {
    for pair in flatten([
      for role_name, role_cfg in var.irsa_roles : [
        for policy_arn in role_cfg.managed_policy_arns : {
          key        = "${role_name}-${policy_arn}"
          role_name  = role_name
          policy_arn = policy_arn
        }
      ]
    ]) : pair.key => pair
  }

  role       = aws_iam_role.irsa[each.value.role_name].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_role_policy" "irsa_inline" {
  for_each = {
    for role_name, role_cfg in var.irsa_roles : role_name => role_cfg
    if role_cfg.inline_policy_json != null
  }

  name   = "${var.name_prefix}-${each.key}-inline"
  role   = aws_iam_role.irsa[each.key].id
  policy = each.value.inline_policy_json
}
