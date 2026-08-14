output "node_group_name" {
  description = "EKS node group name."
  value       = aws_eks_node_group.this.node_group_name
}

output "node_group_arn" {
  description = "EKS node group ARN."
  value       = aws_eks_node_group.this.arn
}

output "node_role_arn" {
  description = "IAM role ARN used by the node group."
  value       = aws_iam_role.node.arn
}
