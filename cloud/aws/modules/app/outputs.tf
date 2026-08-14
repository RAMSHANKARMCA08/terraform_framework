output "namespace" {
  description = "Namespace created for the application."
  value       = kubernetes_namespace.this.metadata[0].name
}

output "deployment_name" {
  description = "Deployment name."
  value       = kubernetes_deployment.this.metadata[0].name
}

output "service_name" {
  description = "Service name."
  value       = kubernetes_service.this.metadata[0].name
}
