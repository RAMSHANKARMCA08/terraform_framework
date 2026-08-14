output "gateway_endpoint_ids" {
  value = { for name, endpoint in aws_vpc_endpoint.gateway : name => endpoint.id }
}
output "interface_endpoint_ids" {
  value = { for name, endpoint in aws_vpc_endpoint.interface : name => endpoint.id }
}

