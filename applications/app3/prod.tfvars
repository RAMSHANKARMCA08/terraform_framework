application_overrides = {
  app3 = {
    namespace        = "app3"
    image_repository = "333333333333.dkr.ecr.us-east-1.amazonaws.com/app3"
    image_tag        = "v1.2.0"
    replicas         = 3
    container_port   = 8080
    service_port     = 80
    service_type     = "ClusterIP"
    resources = {
      requests = { cpu = "250m", memory = "512Mi" }
      limits   = { cpu = "1000m", memory = "1Gi" }
    }
    env_vars                    = { APP_ENV = "prod" }
    secret_env_vars             = []
    config_map_data             = {}
    enable_ingress              = true
    ingress_host                = "app3.example.com"
    ingress_annotations         = { "alb.ingress.kubernetes.io/group.name" = "apps-prod" }
    hpa                         = { enabled = true, min_replicas = 3, max_replicas = 10, target_cpu_utilization_percentage = 60 }
    pdb                         = { enabled = true, min_available = "2" }
    labels                      = { app = "app3" }
    liveness_probe              = { path = "/healthz", port = 8080, initial_delay_seconds = 30, period_seconds = 10, timeout_seconds = 5, failure_threshold = 3 }
    readiness_probe             = { path = "/readyz", port = 8080, initial_delay_seconds = 10, period_seconds = 10, timeout_seconds = 5, failure_threshold = 3 }
    topology_spread_constraints = [{ max_skew = 1, topology_key = "topology.kubernetes.io/zone", when_unsatisfiable = "ScheduleAnyway" }]
  }
}
selected_apps       = ["app3"]
enable_applications = true
