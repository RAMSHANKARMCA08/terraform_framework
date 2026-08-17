output "alb_dns_name" { value = module.alb.dns_name }
output "alb_zone_id" { value = module.alb.zone_id }
output "alb_arn" { value = module.alb.arn }
output "target_group_arn" { value = module.alb.target_group_arn }
output "instance_id" { value = var.use_autoscaling ? null : aws_instance.this[0].id }
