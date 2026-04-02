output "container_registry_ids" {
  description = "Container Registry resource IDs keyed by input key."
  value       = { for k, v in module.acr : k => v.resource_id }
}

output "container_registry_names" {
  description = "Container Registry names keyed by input key."
  value       = { for k, v in module.acr : k => v.name }
}

output "container_registry_resources" {
  description = "Full AVM resource outputs keyed by input key."
  value       = { for k, v in module.acr : k => v.resource }
}
