module "acr" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "0.5.1"

  for_each = var.container_registries

  name                = each.value.name
  location            = each.value.location
  resource_group_name = try(each.value.resource_group_name, null) != null ? each.value.resource_group_name : var.resource_groups[each.value.resource_group_key].name

  admin_enabled                           = try(each.value.admin_enabled, false)
  anonymous_pull_enabled                  = try(each.value.anonymous_pull_enabled, false)
  customer_managed_key                    = try(each.value.customer_managed_key, null)
  data_endpoint_enabled                   = try(each.value.data_endpoint_enabled, false)
  diagnostic_settings                     = try(each.value.diagnostic_settings, {})
  enable_trust_policy                     = try(each.value.enable_trust_policy, false)
  export_policy_enabled                   = try(each.value.export_policy_enabled, true)
  georeplications                         = try(each.value.georeplications, [])
  lock                                    = try(each.value.lock, null)
  managed_identities                      = try(each.value.managed_identities, {})
  network_rule_bypass_option              = try(each.value.network_rule_bypass_option, null)
  network_rule_set                        = try(each.value.network_rule_set, null)
  private_endpoints_manage_dns_zone_group = try(each.value.private_endpoints_manage_dns_zone_group, null)
  public_network_access_enabled           = try(each.value.public_network_access_enabled, null)
  quarantine_policy_enabled               = try(each.value.quarantine_policy_enabled, false)
  retention_policy_in_days                = try(each.value.retention_policy_in_days, 7)
  role_assignments                        = try(each.value.role_assignments, {})
  scope_maps                              = try(each.value.scope_maps, {})
  sku                                     = try(each.value.sku, null)
  tags                                    = try(each.value.tags, null)
  zone_redundancy_enabled                 = try(each.value.zone_redundancy_enabled, true)

  private_endpoints = {
    for pe_k, pe in try(each.value.private_endpoints, {}) : pe_k => {
      name = try(pe.name, null)

      role_assignments = try(pe.role_assignments, {})

      lock = try(pe.lock, null)
      tags = try(pe.tags, null)

      subnet_resource_id = coalesce(
        try(pe.subnet_resource_id, null),
        try(pe.network_configuration.subnet_resource_id, null),
        try(var.virtual_networks[pe.network_configuration.virtual_network_key].subnets[pe.network_configuration.subnet_key].resource_id, null)
      )

      private_dns_zone_group_name = try(pe.private_dns_zone_group_name, "default")
      private_dns_zone_resource_ids = setunion(
        toset(coalesce(try(pe.private_dns_zone_resource_ids, null), [])),
        toset([for k in coalesce(try(pe.private_dns_zone.keys, null), []) : var.private_dns_zones[k].resource_id])
      )

      application_security_group_associations = try(pe.application_security_group_associations, {})
      private_service_connection_name         = try(pe.private_service_connection_name, null)
      network_interface_name                  = try(pe.network_interface_name, null)
      location                                = try(pe.location, null)
      resource_group_name                     = try(pe.resource_group_name, null)

      ip_configurations = try(pe.ip_configurations, {})
    }
  }

  enable_telemetry = try(each.value.enable_telemetry, var.enable_telemetry)
}
