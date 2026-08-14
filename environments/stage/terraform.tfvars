project     = "eks-platform"
owner       = "platform-team"
environment = "stage"
aws_region  = "us-east-1"

cluster_name       = "eks-platform-stage"
kubernetes_version = "1.31"

vpc_cidr             = "10.10.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]

single_nat_gateway        = true
cluster_api_ingress_cidrs = ["10.0.0.0/8"]
endpoint_private_access   = true
endpoint_public_access    = false
public_access_cidrs       = []

enabled_cluster_log_types = ["api", "audit", "authenticator"]
log_retention_days        = 14

node_groups = {
  general = {
    instance_types                 = ["t3.large"]
    capacity_type                  = "ON_DEMAND"
    desired_size                   = 2
    max_size                       = 4
    min_size                       = 2
    disk_size                      = 50
    ami_type                       = "AL2_x86_64"
    labels                         = { workload = "general" }
    taints                         = []
    max_unavailable_percentage     = 33
    additional_managed_policy_arns = []
  }
}

enable_kubernetes_providers = false
enable_alb_controller       = false
enable_applications         = false

application_defaults = {
  app1 = {
    namespace        = "app1"
    image_repository = "111111111111.dkr.ecr.us-east-1.amazonaws.com/app1"
    image_tag        = "v1.0.0"
    replicas         = 1
    container_port   = 8080
    service_port     = 80
    service_type     = "ClusterIP"
    resources = {
      requests = { cpu = "100m", memory = "256Mi" }
      limits   = { cpu = "500m", memory = "512Mi" }
    }
    env_vars = { APP_ENV = "dev" }
    secret_env_vars = [
      {
        name        = "DATABASE_URL"
        secret_name = "app1-secrets"
        secret_key  = "database_url"
        optional    = false
      }
    ]
    config_map_data     = {}
    enable_ingress      = true
    ingress_host        = "app1-dev.example.com"
    ingress_annotations = { "alb.ingress.kubernetes.io/group.name" = "apps-dev" }
    hpa = {
      enabled                           = true
      min_replicas                      = 1
      max_replicas                      = 3
      target_cpu_utilization_percentage = 70
    }
    pdb = {
      enabled       = true
      min_available = "1"
    }
    labels = { tier = "backend" }
    liveness_probe = {
      path                  = "/healthz"
      port                  = 8080
      initial_delay_seconds = 30
      period_seconds        = 10
      timeout_seconds       = 5
      failure_threshold     = 3
    }
    readiness_probe = {
      path                  = "/readyz"
      port                  = 8080
      initial_delay_seconds = 10
      period_seconds        = 10
      timeout_seconds       = 5
      failure_threshold     = 3
    }
    topology_spread_constraints = [{
      max_skew           = 1
      topology_key       = "topology.kubernetes.io/zone"
      when_unsatisfiable = "ScheduleAnyway"
    }]
  }

  app2 = {
    namespace        = "app2"
    image_repository = "111111111111.dkr.ecr.us-east-1.amazonaws.com/app2"
    image_tag        = "v1.0.0"
    replicas         = 1
    container_port   = 8080
    service_port     = 80
    service_type     = "ClusterIP"
    resources = {
      requests = { cpu = "100m", memory = "256Mi" }
      limits   = { cpu = "500m", memory = "512Mi" }
    }
    env_vars            = { APP_ENV = "dev" }
    secret_env_vars     = []
    config_map_data     = {}
    enable_ingress      = true
    ingress_host        = "app2-dev.example.com"
    ingress_annotations = { "alb.ingress.kubernetes.io/group.name" = "apps-dev" }
    hpa = {
      enabled                           = true
      min_replicas                      = 1
      max_replicas                      = 3
      target_cpu_utilization_percentage = 70
    }
    pdb = {
      enabled       = true
      min_available = "1"
    }
    labels = { tier = "backend" }
    liveness_probe = {
      path                  = "/healthz"
      port                  = 8080
      initial_delay_seconds = 30
      period_seconds        = 10
      timeout_seconds       = 5
      failure_threshold     = 3
    }
    readiness_probe = {
      path                  = "/readyz"
      port                  = 8080
      initial_delay_seconds = 10
      period_seconds        = 10
      timeout_seconds       = 5
      failure_threshold     = 3
    }
    topology_spread_constraints = [{
      max_skew           = 1
      topology_key       = "topology.kubernetes.io/zone"
      when_unsatisfiable = "ScheduleAnyway"
    }]
  }

  app3 = {
    namespace        = "app3"
    image_repository = "111111111111.dkr.ecr.us-east-1.amazonaws.com/app3"
    image_tag        = "v1.0.0"
    replicas         = 1
    container_port   = 8080
    service_port     = 80
    service_type     = "ClusterIP"
    resources = {
      requests = { cpu = "100m", memory = "256Mi" }
      limits   = { cpu = "500m", memory = "512Mi" }
    }
    env_vars            = { APP_ENV = "dev" }
    secret_env_vars     = []
    config_map_data     = {}
    enable_ingress      = true
    ingress_host        = "app3-dev.example.com"
    ingress_annotations = { "alb.ingress.kubernetes.io/group.name" = "apps-dev" }
    hpa = {
      enabled                           = true
      min_replicas                      = 1
      max_replicas                      = 3
      target_cpu_utilization_percentage = 70
    }
    pdb = {
      enabled       = true
      min_available = "1"
    }
    labels = { tier = "backend" }
    liveness_probe = {
      path                  = "/healthz"
      port                  = 8080
      initial_delay_seconds = 30
      period_seconds        = 10
      timeout_seconds       = 5
      failure_threshold     = 3
    }
    readiness_probe = {
      path                  = "/readyz"
      port                  = 8080
      initial_delay_seconds = 10
      period_seconds        = 10
      timeout_seconds       = 5
      failure_threshold     = 3
    }
    topology_spread_constraints = [{
      max_skew           = 1
      topology_key       = "topology.kubernetes.io/zone"
      when_unsatisfiable = "ScheduleAnyway"
    }]
  }
}

tags = {
  CostCenter = "platform"
}

enable_cluster_autoscaler = true
enable_external_dns       = false
enable_waf                = false
