variable "app_name" {
  description = "Application name."
  type        = string
}

variable "project_name" {
  description = "Project name label value applied to Kubernetes resources."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the application."
  type        = string
}

variable "image_repository" {
  description = "Container image repository URL."
  type        = string
}

variable "image_tag" {
  description = "Container image tag."
  type        = string
}

variable "replicas" {
  description = "Desired replica count."
  type        = number
}

variable "container_port" {
  description = "Application container port."
  type        = number
  default     = 8080
}

variable "service_port" {
  description = "Kubernetes service port."
  type        = number
  default     = 80
}

variable "service_type" {
  description = "Kubernetes service type."
  type        = string
  default     = "ClusterIP"
}

variable "resources" {
  description = "Resource requests and limits."
  type = object({
    requests = map(string)
    limits   = map(string)
  })
}

variable "env_vars" {
  description = "Non-secret environment variables."
  type        = map(string)
  default     = {}
}

variable "secret_env_vars" {
  description = "Environment variables sourced from existing Kubernetes Secrets."
  type = list(object({
    name        = string
    secret_name = string
    secret_key  = string
    optional    = optional(bool, false)
  }))
  default = []
}

variable "config_map_data" {
  description = "ConfigMap key/value data."
  type        = map(string)
  default     = {}
}

variable "enable_ingress" {
  description = "Whether to create ingress resource."
  type        = bool
  default     = true
}

variable "ingress_host" {
  description = "Ingress hostname."
  type        = string
  default     = null
}

variable "ingress_annotations" {
  description = "Additional ingress annotations."
  type        = map(string)
  default     = {}
}

variable "hpa" {
  description = "Horizontal Pod Autoscaler settings."
  type = object({
    enabled                           = bool
    min_replicas                      = number
    max_replicas                      = number
    target_cpu_utilization_percentage = number
  })
  default = {
    enabled                           = false
    min_replicas                      = 1
    max_replicas                      = 2
    target_cpu_utilization_percentage = 70
  }
}

variable "pdb" {
  description = "Pod disruption budget settings."
  type = object({
    enabled       = bool
    min_available = string
  })
  default = {
    enabled       = false
    min_available = "1"
  }
}

variable "liveness_probe" {
  description = "Liveness probe configuration."
  type = object({
    path                  = string
    port                  = number
    initial_delay_seconds = number
    period_seconds        = number
    timeout_seconds       = number
    failure_threshold     = number
  })
  default = {
    path                  = "/healthz"
    port                  = 8080
    initial_delay_seconds = 30
    period_seconds        = 10
    timeout_seconds       = 5
    failure_threshold     = 3
  }
}

variable "readiness_probe" {
  description = "Readiness probe configuration."
  type = object({
    path                  = string
    port                  = number
    initial_delay_seconds = number
    period_seconds        = number
    timeout_seconds       = number
    failure_threshold     = number
  })
  default = {
    path                  = "/readyz"
    port                  = 8080
    initial_delay_seconds = 10
    period_seconds        = 10
    timeout_seconds       = 5
    failure_threshold     = 3
  }
}

variable "topology_spread_constraints" {
  description = "Topology spread constraints to improve high availability."
  type = list(object({
    max_skew           = number
    topology_key       = string
    when_unsatisfiable = string
  }))
  default = [{
    max_skew           = 1
    topology_key       = "topology.kubernetes.io/zone"
    when_unsatisfiable = "ScheduleAnyway"
  }]
}

variable "labels" {
  description = "Additional Kubernetes labels."
  type        = map(string)
  default     = {}
}
