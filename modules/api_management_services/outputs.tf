output "api_management_service_ids" {
  description = "API Management service resource IDs keyed by input key."
  value       = { for k, v in module.apim : k => v.resource_id }
}

output "api_management_gateway_urls" {
  description = "API Management gateway URLs keyed by input key."
  value       = { for k, v in module.apim : k => v.apim_gateway_url }
}
