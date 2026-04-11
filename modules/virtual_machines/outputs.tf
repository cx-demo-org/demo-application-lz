output "virtual_machine_resource_ids" {
  description = "Virtual machine resource IDs keyed by var.virtual_machines key."
  value       = { for k, v in module.virtual_machine : k => v.resource_id }
}

output "virtual_machine_azurerm" {
  description = "Default azurerm-exported VM attributes keyed by var.virtual_machines key."
  value       = { for k, v in module.virtual_machine : k => v.virtual_machine_azurerm }
}
