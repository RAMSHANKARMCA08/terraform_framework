output "application_url" { value = "https://${var.domain_name}/${var.application}" }
output "origin_url" { value = "http://origin-${var.application}.${var.domain_name}:30080" }
output "nodeport_url" { value = "http://${one(data.aws_instances.worker.public_ips)}:30080" }
output "cluster_name" { value = module.eks.cluster_name }
output "worker_public_ip" { value = one(data.aws_instances.worker.public_ips) }
output "route53_zone_id" { value = data.aws_route53_zone.existing.zone_id }
