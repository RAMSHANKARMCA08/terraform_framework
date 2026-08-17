output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID associated with control plane."
  value       = aws_security_group.cluster.id
}

output "managed_cluster_security_group_id" {
  description = "EKS-managed cluster security group also attached to managed nodes."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA trust policies."
  value       = aws_iam_openid_connect_provider.this.url
}

output "kms_key_arn" {
  description = "KMS key ARN used to encrypt Kubernetes secrets."
  value       = aws_kms_key.this.arn
}
