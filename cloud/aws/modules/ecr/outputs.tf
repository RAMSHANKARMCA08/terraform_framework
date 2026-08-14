output "repository_urls" {
  description = "ECR repository URLs keyed by repository name."
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "ECR repository ARNs keyed by repository name."
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}
