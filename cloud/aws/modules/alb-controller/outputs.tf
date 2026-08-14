output "iam_role_arn" {
  description = "IRSA IAM role ARN used by AWS Load Balancer Controller."
  value       = aws_iam_role.this.arn
}

output "helm_release_name" {
  description = "Helm release name."
  value       = helm_release.this.name
}
