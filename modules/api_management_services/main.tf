module "apim" {
  source  = "Azure/avm-res-apimanagement-service/azurerm"
  version = "0.0.7"

  for_each = var.api_management_services

  name                = each.value.name
  location            = each.value.location
  resource_group_name = try(each.value.resource_group_name, null) != null ? each.value.resource_group_name : var.resource_groups[each.value.resource_group_key].name
  publisher_email     = each.value.publisher_email

  additional_location = try(each.value.additional_location, [])
  api_version_sets    = try(each.value.api_version_sets, {})
  apis                = try(each.value.apis, {})
  certificate         = try(each.value.certificate, [])

  client_certificate_enabled = try(each.value.client_certificate_enabled, false)
  delegation                 = try(each.value.delegation, null)
  gateway_disabled           = try(each.value.gateway_disabled, false)
  hostname_configuration     = try(each.value.hostname_configuration, null)

  publisher_name                = try(each.value.publisher_name, null)
  sku_name                      = try(each.value.sku_name, null)
  zones                         = try(each.value.zones, null)
  public_network_access_enabled = try(each.value.public_network_access_enabled, null)

  min_api_version           = try(each.value.min_api_version, null)
  named_values              = try(each.value.named_values, {})
  notification_sender_email = try(each.value.notification_sender_email, null)
  policy                    = try(each.value.policy, null)
  products                  = try(each.value.products, {})
  protocols                 = try(each.value.protocols, null)
  public_ip_address_id      = try(each.value.public_ip_address_id, null)
  security                  = try(each.value.security, null)
  sign_in                   = try(each.value.sign_in, null)
  sign_up                   = try(each.value.sign_up, null)
  subscriptions             = try(each.value.subscriptions, {})
  tenant_access             = try(each.value.tenant_access, null)

  virtual_network_type = try(each.value.virtual_network_type, "None")
  virtual_network_subnet_id = try(each.value.virtual_network_subnet_id, null) != null ? each.value.virtual_network_subnet_id : (
    try(each.value.virtual_network_configuration, null) != null ? (
      try(each.value.virtual_network_configuration.subnet_resource_id, null) != null ? each.value.virtual_network_configuration.subnet_resource_id : (
        var.virtual_networks[each.value.virtual_network_configuration.virtual_network_key].subnets[each.value.virtual_network_configuration.subnet_key].resource_id
      )
    ) : null
  )

  diagnostic_settings = try(each.value.diagnostic_settings, {})
  managed_identities  = try(each.value.managed_identities, {})
  lock                = try(each.value.lock, null)
  role_assignments    = try(each.value.role_assignments, {})

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
  private_endpoints_manage_dns_zone_group = try(each.value.private_endpoints_manage_dns_zone_group, null)

  tags             = try(each.value.tags, null)
  enable_telemetry = try(each.value.enable_telemetry, var.enable_telemetry)
}
