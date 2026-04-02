module "mongo_cluster" {
  source  = "Azure/avm-res-documentdb-mongocluster/azurerm"
  version = "0.1.0"

  for_each = var.mongo_clusters

  name                = each.value.name
  location            = each.value.location
  resource_group_name = coalesce(try(each.value.resource_group_name, null), var.resource_groups[each.value.resource_group_key].name)

  administrator_login          = each.value.administrator_login
  administrator_login_password = coalesce(try(var.mongo_cluster_admin_passwords[each.key], null), each.value.administrator_login_password)

  backup_policy_type = each.value.backup_policy_type
  compute_tier       = each.value.compute_tier

  customer_managed_key = each.value.customer_managed_key

  diagnostic_settings = each.value.diagnostic_settings

  enable_ha        = each.value.enable_ha
  enable_telemetry = coalesce(try(each.value.enable_telemetry, null), var.enable_telemetry)

  firewall_rules = each.value.firewall_rules

  ha_mode            = each.value.ha_mode
  lock               = each.value.lock
  managed_identities = each.value.managed_identities

  node_count = each.value.node_count

  private_endpoints_manage_dns_zone_group = each.value.private_endpoints_manage_dns_zone_group

  private_endpoints = {
    for pe_k, pe in each.value.private_endpoints : pe_k => {
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
        toset(coalesce(try(pe.private_dns_zone.resource_ids, null), [])),
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

  public_network_access = each.value.public_network_access

  role_assignments = each.value.role_assignments

  server_version  = each.value.server_version
  shard_count     = each.value.shard_count
  storage_size_gb = each.value.storage_size_gb

  tags = each.value.tags
}
