application_overrides = {
  app1 = {
    namespace        = "app1"
    image_repository = "222222222222.dkr.ecr.us-east-1.amazonaws.com/app1"
    image_tag        = "v1.1.0-rc1"
    replicas         = 2
    container_port   = 8080
    service_port     = 80
    service_type     = "ClusterIP"
    resources = {
      requests = { cpu = "200m", memory = "384Mi" }
      limits   = { cpu = "800m", memory = "1Gi" }
    }
    env_vars                    = { APP_ENV = "stage", LOG_LEVEL = "info" }
    secret_env_vars             = []
    config_map_data             = { FEATURE_FLAG_X = "false" }
    enable_ingress              = true
    ingress_host                = "app1-stage.example.com"
    ingress_annotations         = { "alb.ingress.kubernetes.io/group.name" = "apps-stage" }
    hpa                         = { enabled = true, min_replicas = 2, max_replicas = 5, target_cpu_utilization_percentage = 65 }
    pdb                         = { enabled = true, min_available = "1" }
    labels                      = { app = "app1", team = "app-team" }
    liveness_probe              = { path = "/healthz", port = 8080, initial_delay_seconds = 30, period_seconds = 10, timeout_seconds = 5, failure_threshold = 3 }
    readiness_probe             = { path = "/readyz", port = 8080, initial_delay_seconds = 10, period_seconds = 10, timeout_seconds = 5, failure_threshold = 3 }
    topology_spread_constraints = [{ max_skew = 1, topology_key = "topology.kubernetes.io/zone", when_unsatisfiable = "ScheduleAnyway" }]
  }
}
selected_apps       = ["app1"]
enable_applications = true
