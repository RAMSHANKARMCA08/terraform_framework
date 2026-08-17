locals {
  hostname = var.environment == "prod" ? var.domain_name : "${var.environment}.${var.domain_name}"
}

data "aws_route53_zone" "existing" {
  name         = var.domain_name
  private_zone = false
}

data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_acm_certificate" "this" {
  domain_name       = local.hostname
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
  tags = var.tags
}

resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for option in aws_acm_certificate.this.domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      type   = option.resource_record_type
      record = option.resource_record_value
    }
  }
  zone_id         = data.aws_route53_zone.existing.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]
}

resource "aws_cloudfront_function" "path_rewrite" {
  name    = "${replace(local.hostname, ".", "-")}-path-router"
  runtime = "cloudfront-js-2.0"
  comment = "Redirect root and remove application prefix before origin forwarding"
  publish = true
  code = <<-JS
    function handler(event) {
      var request = event.request;
      if (request.uri === "/" || request.uri === "") {
        return {
          statusCode: 302,
          statusDescription: "Found",
          headers: { location: { value: "/${var.default_application}" } }
        };
      }
      var prefixes = ${jsonencode([for application in sort(keys(var.routes)) : "/${application}"])};
      for (var i = 0; i < prefixes.length; i++) {
        if (request.uri === prefixes[i]) {
          request.uri = "/";
          break;
        }
        if (request.uri.indexOf(prefixes[i] + "/") === 0) {
          request.uri = request.uri.substring(prefixes[i].length);
          break;
        }
      }
      return request;
    }
  JS
}

resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  aliases         = [local.hostname]
  comment         = "${local.hostname} shared application path router"
  price_class     = var.price_class
  http_version    = "http2and3"

  dynamic "origin" {
    for_each = var.routes
    content {
      domain_name = origin.value.origin_domain_name
      origin_id   = origin.key
      custom_origin_config {
        http_port              = origin.value.origin_http_port
        https_port             = origin.value.origin_https_port
        origin_protocol_policy = origin.value.origin_protocol
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior {
    target_origin_id         = var.default_application
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
    cache_policy_id          = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_except_host.id
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.path_rewrite.arn
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.routes
    content {
      path_pattern             = "/${ordered_cache_behavior.key}*"
      target_origin_id         = ordered_cache_behavior.key
      viewer_protocol_policy   = "redirect-to-https"
      allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods           = ["GET", "HEAD"]
      compress                 = true
      cache_policy_id          = data.aws_cloudfront_cache_policy.disabled.id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_except_host.id
      function_association {
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.path_rewrite.arn
      }
    }
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.this.certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = contains(keys(var.routes), var.default_application)
      error_message = "default_application must be a key in routes."
    }
  }
}

resource "aws_route53_record" "ipv4" {
  zone_id = data.aws_route53_zone.existing.zone_id
  name    = local.hostname
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "ipv6" {
  zone_id = data.aws_route53_zone.existing.zone_id
  name    = local.hostname
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
