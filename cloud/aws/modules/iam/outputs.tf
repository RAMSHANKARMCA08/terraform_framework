output "irsa_role_arns" {
  description = "IRSA role ARNs keyed by role name."
  value       = { for k, v in aws_iam_role.irsa : k => v.arn }
}
