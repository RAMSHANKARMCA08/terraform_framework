data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

module "alb_sg" {
  source              = "../security-groups"
  name_prefix         = var.name_prefix
  security_group_name = "${var.region_label}-alb"
  description         = "Public HTTPS ingress for ${var.name_prefix} ${var.region_label}"
  vpc_id              = var.vpc_id
  ingress_rules = [
    { protocol = "tcp", from_port = 80, to_port = 80, cidr_ipv4 = "0.0.0.0/0", description = "HTTP redirect" },
    { protocol = "tcp", from_port = 443, to_port = 443, cidr_ipv4 = "0.0.0.0/0", description = "HTTPS" }
  ]
  tags = var.tags
}

module "application_sg" {
  source              = "../security-groups"
  name_prefix         = var.name_prefix
  security_group_name = "${var.region_label}-application"
  description         = "Application traffic from the regional VPC"
  vpc_id              = var.vpc_id
  ingress_rules = [
    { protocol = "tcp", from_port = 80, to_port = 80, cidr_ipv4 = var.vpc_cidr, description = "HTTP from regional ALB" }
  ]
  tags = var.tags
}

module "alb" {
  source = "../alb"

  name               = "${var.name_prefix}-${var.region_label}"
  vpc_id             = var.vpc_id
  subnet_ids         = var.public_subnet_ids
  security_group_ids = [module.alb_sg.security_group_id]
  certificate_arn    = var.certificate_arn
  target_port        = 80
  target_protocol    = "HTTP"
  target_type        = "instance"
  health_check_path  = "/health"
  tags               = var.tags
}

resource "aws_launch_template" "this" {
  name_prefix            = "${var.name_prefix}-${var.region_label}-"
  image_id               = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  key_name               = var.key_name
  update_default_version = true
  vpc_security_group_ids = [module.application_sg.security_group_id]
  user_data = base64encode(<<-EOT
    #!/bin/bash
    set -euo pipefail
    dnf install -y httpd
    server_hostname=$(hostname)
    cat >/var/www/html/index.html <<HTML
    <!doctype html>
    <html><body>
      <h1>Welcome to my application</h1>
      <p>Hostname: $server_hostname</p>
      <p>Location: ${title(var.region_label)}</p>
    </body></html>
    HTML
    printf 'healthy\n' >/var/www/html/health
    systemctl enable --now httpd
  EOT
  )
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }
  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name_prefix}-${var.region_label}" })
  }
  tag_specifications {
    resource_type = "volume"
    tags          = var.tags
  }
  tags = var.tags
}

resource "aws_autoscaling_group" "this" {
  name                = "${var.name_prefix}-${var.region_label}"
  vpc_zone_identifier = var.private_subnet_ids
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  target_group_arns   = [module.alb.target_group_arn]
  health_check_type   = "ELB"
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  dynamic "tag" {
    for_each = merge(var.tags, { Name = "${var.name_prefix}-${var.region_label}" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
