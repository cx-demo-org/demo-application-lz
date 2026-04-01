module "appgw" {
  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "0.5.2"

  for_each = var.application_gateways

  name                = each.value.name
  location            = each.value.location
  resource_group_name = var.resource_groups[each.value.resource_group_key].name

  gateway_ip_configuration = {
    name      = try(each.value.gateway_ip_configuration_name, null)
    subnet_id = var.virtual_networks[each.value.virtual_network_key].subnets[each.value.subnet_key].resource_id
  }

  backend_address_pools = each.value.backend_address_pools
  backend_http_settings = each.value.backend_http_settings
  frontend_ports        = each.value.frontend_ports
  http_listeners        = each.value.http_listeners
  request_routing_rules = each.value.request_routing_rules

  app_gateway_waf_policy_resource_id    = try(each.value.app_gateway_waf_policy_resource_id, null)
  authentication_certificate            = try(each.value.authentication_certificate, null)
  autoscale_configuration               = try(each.value.autoscale_configuration, null)
  custom_error_configuration            = try(each.value.custom_error_configuration, null)
  diagnostic_settings                   = try(each.value.diagnostic_settings, {})
  fips_enabled                          = try(each.value.fips_enabled, null)
  force_firewall_policy_association     = try(each.value.force_firewall_policy_association, true)
  frontend_ip_configuration_private     = try(each.value.frontend_ip_configuration_private, {})
  frontend_ip_configuration_public_name = try(each.value.frontend_ip_configuration_public_name, null)
  global                                = try(each.value.global, null)
  http2_enable                          = try(each.value.http2_enable, true)
  lock                                  = try(each.value.lock, null)
  managed_identities                    = try(each.value.managed_identities, {})
  private_link_configuration            = try(each.value.private_link_configuration, null)
  probe_configurations                  = try(each.value.probe_configurations, null)
  public_ip_address_configuration       = try(each.value.public_ip_address_configuration, {})
  redirect_configuration                = try(each.value.redirect_configuration, null)
  rewrite_rule_set                      = try(each.value.rewrite_rule_set, null)
  role_assignments                      = try(each.value.role_assignments, {})
  sku                                   = try(each.value.sku, null)
  ssl_certificates                      = try(each.value.ssl_certificates, null)
  ssl_policy                            = try(each.value.ssl_policy, null)
  ssl_profile                           = try(each.value.ssl_profile, null)
  timeouts                              = try(each.value.timeouts, null)
  trusted_client_certificate            = try(each.value.trusted_client_certificate, null)
  trusted_root_certificate              = try(each.value.trusted_root_certificate, null)
  url_path_map_configurations           = try(each.value.url_path_map_configurations, null)
  waf_configuration                     = try(each.value.waf_configuration, null)
  zones                                 = try(each.value.zones, null)

  tags             = try(each.value.tags, null)
  enable_telemetry = var.enable_telemetry
}
