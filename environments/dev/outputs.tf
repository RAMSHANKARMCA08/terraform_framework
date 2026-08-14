output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by worker nodes."
  value       = module.vpc.private_subnet_ids
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint."
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN."
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "OIDC issuer URL."
  value       = module.eks.oidc_issuer_url
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded EKS cluster certificate authority data."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "ecr_repository_urls" {
  description = "ECR repository URLs for applications."
  value       = module.ecr.repository_urls
}

