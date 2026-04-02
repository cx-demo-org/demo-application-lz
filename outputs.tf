output "resource_group_ids" {
  description = "Resource group resource IDs, keyed by var.resource_groups key."
  value       = { for k, v in module.virtual_networks.resource_groups : k => v.resource_id }
}

output "virtual_network_ids" {
  description = "VNet resource IDs, keyed by var.virtual_networks key."
  value       = { for k, v in module.virtual_networks.virtual_networks : k => v.resource_id }
}

output "subnet_ids" {
  description = "Subnet resource IDs, keyed by vnet key then subnet key (as provided in var.virtual_networks[*].subnets)."
  value = {
    for vnet_key, vnet_mod in module.virtual_networks.virtual_networks : vnet_key => {
      for subnet_key, subnet_info in vnet_mod.subnets : subnet_key => subnet_info.resource_id
    }
  }
}

output "aks_cluster_ids" {
  description = "AKS cluster resource IDs, keyed by var.aks_clusters key."
  value       = module.aks.aks_cluster_ids
}

output "application_gateway_ids" {
  description = "Application Gateway resource IDs, keyed by var.application_gateways key."
  value       = module.application_gateways.application_gateway_ids
}

output "postgres_fqdns" {
  description = "PostgreSQL Flexible Server FQDNs, keyed by var.postgres_servers key."
  value       = module.postgres_servers.postgres_fqdns
}

output "api_management_service_ids" {
  description = "API Management service resource IDs, keyed by var.api_management_services key."
  value       = module.api_management_services.api_management_service_ids
}

output "api_management_gateway_urls" {
  description = "API Management gateway URLs, keyed by var.api_management_services key."
  value       = module.api_management_services.api_management_gateway_urls
}

output "container_registry_ids" {
  description = "Container Registry (ACR) resource IDs, keyed by var.container_registries key."
  value       = module.container_registries.container_registry_ids
}

output "container_registry_names" {
  description = "Container Registry (ACR) names, keyed by var.container_registries key."
  value       = module.container_registries.container_registry_names
}
