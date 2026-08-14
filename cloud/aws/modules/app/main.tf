locals {
  labels = merge({
    "app.kubernetes.io/name"       = var.app_name
    "app.kubernetes.io/instance"   = "${var.app_name}-${var.environment}"
    "app.kubernetes.io/managed-by" = "terraform"
    "environment"                  = var.environment
    "env"                          = var.environment
    "projectname"                  = var.project_name
  }, var.labels)
}

resource "kubernetes_namespace" "this" {
  metadata {
    name   = var.namespace
    labels = local.labels
  }
}

resource "kubernetes_config_map" "this" {
  count = length(var.config_map_data) > 0 ? 1 : 0

  metadata {
    name      = "${var.app_name}-config"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.labels
  }

  data = var.config_map_data
}

resource "kubernetes_deployment" "this" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    template {
      metadata {
        labels = merge(local.labels, {
          app = var.app_name
        })
      }

      spec {
        dynamic "topology_spread_constraint" {
          for_each = var.topology_spread_constraints
          content {
            max_skew           = topology_spread_constraint.value.max_skew
            topology_key       = topology_spread_constraint.value.topology_key
            when_unsatisfiable = topology_spread_constraint.value.when_unsatisfiable
            label_selector {
              match_labels = {
                app = var.app_name
              }
            }
          }
        }

        container {
          name  = var.app_name
          image = "${var.image_repository}:${var.image_tag}"

          port {
            container_port = var.container_port
          }

          resources {
            requests = var.resources.requests
            limits   = var.resources.limits
          }

          dynamic "env" {
            for_each = var.env_vars
            content {
              name  = env.key
              value = env.value
            }
          }

          dynamic "env" {
            for_each = var.secret_env_vars
            content {
              name = env.value.name
              value_from {
                secret_key_ref {
                  name     = env.value.secret_name
                  key      = env.value.secret_key
                  optional = env.value.optional
                }
              }
            }
          }

          liveness_probe {
            http_get {
              path = var.liveness_probe.path
              port = var.liveness_probe.port
            }
            initial_delay_seconds = var.liveness_probe.initial_delay_seconds
            period_seconds        = var.liveness_probe.period_seconds
            timeout_seconds       = var.liveness_probe.timeout_seconds
            failure_threshold     = var.liveness_probe.failure_threshold
          }

          readiness_probe {
            http_get {
              path = var.readiness_probe.path
              port = var.readiness_probe.port
            }
            initial_delay_seconds = var.readiness_probe.initial_delay_seconds
            period_seconds        = var.readiness_probe.period_seconds
            timeout_seconds       = var.readiness_probe.timeout_seconds
            failure_threshold     = var.readiness_probe.failure_threshold
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.this]
}

resource "kubernetes_service" "this" {
  metadata {
    name      = "${var.app_name}-svc"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.labels
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      name        = "http"
      port        = var.service_port
      target_port = var.container_port
    }

    type = var.service_type
  }
}

resource "kubernetes_ingress_v1" "this" {
  count = var.enable_ingress ? 1 : 0

  metadata {
    name      = "${var.app_name}-ingress"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.labels
    annotations = merge({
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }, var.ingress_annotations)
  }

  spec {
    rule {
      host = var.ingress_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.this.metadata[0].name
              port {
                number = var.service_port
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "this" {
  count = var.hpa.enabled ? 1 : 0

  metadata {
    name      = "${var.app_name}-hpa"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.labels
  }

  spec {
    min_replicas = var.hpa.min_replicas
    max_replicas = var.hpa.max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.this.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa.target_cpu_utilization_percentage
        }
      }
    }
  }
}

resource "kubernetes_pod_disruption_budget_v1" "this" {
  count = var.pdb.enabled ? 1 : 0

  metadata {
    name      = "${var.app_name}-pdb"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.labels
  }

  spec {
    min_available = var.pdb.min_available

    selector {
      match_labels = {
        app = var.app_name
      }
    }
  }
}
