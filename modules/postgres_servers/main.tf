locals {
  postgres_vnet_keys = toset([for _, v in var.postgres_servers : v.virtual_network_key])

  postgres_server_key_by_vnet = {
    for vnet_key in local.postgres_vnet_keys : vnet_key => sort([
      for server_key, server in var.postgres_servers : server_key
      if server.virtual_network_key == vnet_key
    ])[0]
  }

  postgres_private_dns_zone_rg_key = {
    for vnet_key, server_key in local.postgres_server_key_by_vnet : vnet_key => coalesce(
      try(var.postgres_servers[server_key].private_dns_zone_resource_group_key, null),
      var.postgres_servers[server_key].resource_group_key
    )
  }
}

module "private_dns_zones" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"

  for_each = local.postgres_vnet_keys

  domain_name = "privatelink.postgres.database.azure.com"
  parent_id   = var.resource_groups[local.postgres_private_dns_zone_rg_key[each.key]].resource_id

  virtual_network_links = {
    vnet = {
      name               = "link-${var.virtual_networks[each.key].name}"
      virtual_network_id = var.virtual_networks[each.key].resource_id
    }
  }

  tags             = null
  enable_telemetry = var.enable_telemetry
}

module "pg" {
  source  = "Azure/avm-res-dbforpostgresql-flexibleserver/azurerm"
  version = "0.2.0"

  for_each = var.postgres_servers

  name                = each.value.name
  location            = each.value.location
  resource_group_name = var.resource_groups[each.value.resource_group_key].name

  delegated_subnet_id = var.virtual_networks[each.value.virtual_network_key].subnets[each.value.delegated_subnet_key].resource_id
  private_dns_zone_id = module.private_dns_zones[each.value.virtual_network_key].resource_id

  # Flexible Server private access is typically achieved via delegated subnet + private DNS.
  # Private Endpoints (Private Link) are not supported in all offers/regions.
  # Only create Private Endpoints when explicitly supplied in tfvars.
  private_endpoints = coalesce(try(each.value.private_endpoints, null), {})

  administrator_login               = try(each.value.administrator_login, null)
  administrator_password            = try(each.value.administrator_password, null)
  administrator_password_wo         = try(each.value.administrator_password_wo, null)
  administrator_password_wo_version = try(each.value.administrator_password_wo_version, null)
  authentication                    = try(each.value.authentication, null)

  sku_name       = try(each.value.sku_name, null)
  server_version = try(each.value.server_version, null)
  storage_mb     = try(each.value.storage_mb, null)
  storage_tier   = try(each.value.storage_tier, null)
  zone           = try(each.value.zone, null)

  public_network_access_enabled = try(each.value.public_network_access_enabled, false)

  databases      = try(each.value.databases, {})
  firewall_rules = try(each.value.firewall_rules, {})

  # Some regions/offers disable Multi-AZ HA. If you don't need HA, omit the
  # `high_availability` block entirely.
  # Note: AzureRM only accepts ZoneRedundant or SameZone. It does not accept
  # a "Disabled" mode.
  high_availability = (
    try(each.value.high_availability, null) != null &&
    try(lower(each.value.high_availability.mode), "") != "disabled"
  ) ? each.value.high_availability : null

  tags             = try(each.value.tags, null)
  enable_telemetry = var.enable_telemetry
}
