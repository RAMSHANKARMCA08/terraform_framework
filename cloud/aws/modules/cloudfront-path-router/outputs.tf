output "hostname" { value = local.hostname }
output "distribution_id" { value = aws_cloudfront_distribution.this.id }
output "distribution_domain_name" { value = aws_cloudfront_distribution.this.domain_name }
output "application_urls" {
  value = { for application in keys(var.routes) : application => "https://${local.hostname}/${application}" }
}
