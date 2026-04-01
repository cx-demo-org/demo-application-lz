output "application_gateway_ids" {
  description = "Application Gateway resource IDs keyed by input key."
  value       = { for k, v in module.appgw : k => v.application_gateway_id }
}
