data "azurerm_client_config" "current" {}

locals {
  aks_admin_group_object_ids = {
    for k, v in var.aks_clusters : k => (
      try(v.aad_admin_group_object_ids, null) != null && length(v.aad_admin_group_object_ids) > 0
      ? v.aad_admin_group_object_ids
      : [data.azurerm_client_config.current.object_id]
    )
  }

  aks_create_uami = {
    for k, v in var.aks_clusters : k => (
      try(v.avm.managed_identities, null) == null && try(v.avm.service_principal_profile, null) == null
    )
  }

  # Typed "empty" objects used as safe defaults when an optional override is null.
  # Terraform requires both branches of conditionals / coalesce arguments to have
  # consistent object types.
  empty_api_server_access_profile = {
    authorized_ip_ranges               = null
    disable_run_command                = null
    enable_private_cluster             = null
    enable_private_cluster_public_fqdn = null
    enable_vnet_integration            = null
    private_dns_zone                   = null
    subnet_id                          = null
  }

  empty_aad_profile = {
    admin_group_object_ids = null
    client_app_id          = null
    enable_azure_rbac      = null
    managed                = null
    server_app_id          = null
    server_app_secret      = null
    tenant_id              = null
  }

  default_addon_profile_azure_policy = {
    enabled = false
    config  = null
  }
}

module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  for_each = var.aks_clusters

  name                = coalesce(try(each.value.law_name, null), "${each.value.name}-law")
  location            = each.value.location
  resource_group_name = var.resource_groups[each.value.resource_group_key].name

  log_analytics_workspace_retention_in_days = try(each.value.law_retention_in_days, 30)
  log_analytics_workspace_sku               = try(each.value.law_sku, "PerGB2018")

  tags             = try(each.value.tags, null)
  enable_telemetry = var.enable_telemetry
}

module "aks_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.5.0"

  for_each = {
    for k, v in var.aks_clusters : k => v if local.aks_create_uami[k]
  }

  name                = coalesce(try(each.value.identity_name, null), "uami-${each.value.name}")
  location            = each.value.location
  resource_group_name = var.resource_groups[each.value.resource_group_key].name

  role_assignments = {
    vnet_network_contributor = {
      role_definition_id_or_name = "Network Contributor"
      scope                      = var.virtual_networks[each.value.virtual_network_key].resource_id
    }
  }

  tags             = try(each.value.tags, null)
  enable_telemetry = var.enable_telemetry
}

module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "0.4.2"

  for_each = var.aks_clusters

  location  = coalesce(try(each.value.avm.location, null), each.value.location)
  name      = coalesce(try(each.value.avm.name, null), each.value.name)
  parent_id = coalesce(try(each.value.avm.parent_id, null), var.resource_groups[each.value.resource_group_key].resource_id)

  dns_prefix = coalesce(try(each.value.avm.dns_prefix, null), try(each.value.dns_prefix, null), each.value.name)

  node_resource_group = coalesce(try(each.value.avm.node_resource_group, null), each.value.node_resource_group)

  managed_identities = coalesce(
    try(each.value.avm.managed_identities, null),
    try(each.value.avm.service_principal_profile, null) != null
    ? {
      system_assigned            = false
      user_assigned_resource_ids = []
    }
    : {
      # Azure ARM API currently rejects the combined identity type
      # "SystemAssigned, UserAssigned" for the managed cluster.
      # Default to UserAssigned-only unless overridden via `avm.managed_identities`.
      system_assigned            = false
      user_assigned_resource_ids = toset([module.aks_identity[each.key].resource_id])
    }
  )

  default_agent_pool = coalesce(
    try(each.value.avm.default_agent_pool, null),
    {
      name                = try(each.value.default_agent_pool.name, "system")
      vm_size             = try(each.value.default_agent_pool.vm_size, "Standard_DS2_v2")
      enable_auto_scaling = try(each.value.default_agent_pool.enable_auto_scaling, true)
      min_count           = try(each.value.default_agent_pool.min_count, 2)
      max_count           = try(each.value.default_agent_pool.max_count, 4)
      max_pods            = try(each.value.default_agent_pool.max_pods, 30)

      vnet_subnet_id = var.virtual_networks[each.value.virtual_network_key].subnets[each.value.subnet_nodes_key].resource_id

      upgrade_settings = {
        max_surge = try(each.value.default_agent_pool.upgrade_max_surge, "10%")
      }
    }
  )

  api_server_access_profile = merge(
    {
      authorized_ip_ranges               = []
      disable_run_command                = null
      enable_private_cluster             = try(each.value.private_cluster, true)
      enable_private_cluster_public_fqdn = false
      enable_vnet_integration            = true
      private_dns_zone                   = "system"
      subnet_id                          = var.virtual_networks[each.value.virtual_network_key].subnets[each.value.subnet_apiserver_key].resource_id
    },
    {
      for k, v in coalesce(try(each.value.avm.api_server_access_profile, null), local.empty_api_server_access_profile) : k => v
      if v != null
    }
  )

  # We are not using legacy AAD application integration.
  # Passing an `aad_profile` object with unset legacy app fields can cause Azure ARM
  # to reject the request (e.g., `aadProfile.clientAppID = null`).
  # If AAD integration is required later, it must be configured explicitly via
  # `aks_clusters[*].avm.aad_profile`.
  aad_profile = try(each.value.avm.aad_profile, null)

  network_profile = merge(
    {
      dns_service_ip      = try(each.value.network_profile.dns_service_ip, "10.10.200.10")
      service_cidr        = try(each.value.network_profile.service_cidr, "10.10.200.0/24")
      pod_cidr            = try(each.value.network_profile.pod_cidr, "10.244.0.0/16")
      network_plugin      = try(each.value.network_profile.network_plugin, "azure")
      network_plugin_mode = try(each.value.network_profile.network_plugin_mode, "overlay")
      network_policy      = try(each.value.network_profile.network_policy, "azure")
      outbound_type       = try(each.value.network_profile.outbound_type, "userDefinedRouting")
    },
    coalesce(try(each.value.avm.network_profile, null), {})
  )

  addon_profile_oms_agent = coalesce(
    try(each.value.avm.addon_profile_oms_agent, null),
    {
      enabled = try(each.value.enable_oms_agent, true)
      config = {
        log_analytics_workspace_resource_id = module.log_analytics[each.key].resource_id
        use_aad_auth                        = true
      }
    }
  )

  addon_profile_azure_policy                = coalesce(try(each.value.avm.addon_profile_azure_policy, null), local.default_addon_profile_azure_policy)
  addon_profile_confidential_computing      = try(each.value.avm.addon_profile_confidential_computing, null)
  addon_profile_ingress_application_gateway = try(each.value.avm.addon_profile_ingress_application_gateway, null)
  addon_profile_key_vault_secrets_provider  = try(each.value.avm.addon_profile_key_vault_secrets_provider, null)
  addon_profiles_extra                      = coalesce(try(each.value.avm.addon_profiles_extra, null), {})

  # Upstream AVM validates `agent_pools` with a `for` expression, so it must not be null.
  agent_pools                      = try(each.value.avm.agent_pools, null) == null ? {} : each.value.avm.agent_pools
  agentpool_timeouts               = try(each.value.avm.agentpool_timeouts, null)
  ai_toolchain_operator_profile    = try(each.value.avm.ai_toolchain_operator_profile, null)
  auto_scaler_profile              = try(each.value.avm.auto_scaler_profile, null)
  auto_upgrade_profile             = try(each.value.avm.auto_upgrade_profile, null)
  azure_monitor_profile            = try(each.value.avm.azure_monitor_profile, null)
  bootstrap_profile                = try(each.value.avm.bootstrap_profile, null)
  cluster_timeouts                 = try(each.value.avm.cluster_timeouts, null)
  create_agentpools_before_destroy = coalesce(try(each.value.avm.create_agentpools_before_destroy, null), false)

  diagnostic_settings                     = coalesce(try(each.value.avm.diagnostic_settings, null), {})
  disable_local_accounts                  = coalesce(try(each.value.avm.disable_local_accounts, null), false)
  disk_encryption_set_id                  = try(each.value.avm.disk_encryption_set_id, null)
  enable_rbac                             = coalesce(try(each.value.avm.enable_rbac, null), true)
  enable_telemetry                        = coalesce(try(each.value.avm.enable_telemetry, null), var.enable_telemetry)
  extended_location                       = try(each.value.avm.extended_location, null)
  fqdn_subdomain                          = try(each.value.avm.fqdn_subdomain, null)
  http_proxy_config                       = try(each.value.avm.http_proxy_config, null)
  identity_profile                        = try(each.value.avm.identity_profile, null)
  ingress_profile                         = try(each.value.avm.ingress_profile, null)
  kind                                    = try(each.value.avm.kind, null)
  kubernetes_version                      = try(each.value.avm.kubernetes_version, null)
  linux_profile                           = try(each.value.avm.linux_profile, null)
  lock                                    = try(each.value.avm.lock, null)
  metrics_profile                         = try(each.value.avm.metrics_profile, null)
  node_provisioning_profile               = try(each.value.avm.node_provisioning_profile, null)
  node_resource_group_profile             = try(each.value.avm.node_resource_group_profile, null)
  oidc_issuer_profile                     = try(each.value.avm.oidc_issuer_profile, null)
  pod_identity_profile                    = try(each.value.avm.pod_identity_profile, null)
  private_endpoints                       = coalesce(try(each.value.avm.private_endpoints, null), {})
  private_endpoints_manage_dns_zone_group = coalesce(try(each.value.avm.private_endpoints_manage_dns_zone_group, null), true)
  private_link_resources                  = try(each.value.avm.private_link_resources, null)
  public_network_access                   = try(each.value.avm.public_network_access, null)
  role_assignments                        = coalesce(try(each.value.avm.role_assignments, null), {})
  security_profile                        = try(each.value.avm.security_profile, null)
  service_mesh_profile                    = try(each.value.avm.service_mesh_profile, null)
  service_principal_profile               = try(each.value.avm.service_principal_profile, null)
  sku                                     = coalesce(try(each.value.avm.sku, null), { name = "Base", tier = "Standard" })
  storage_profile                         = try(each.value.avm.storage_profile, null)
  support_plan                            = try(each.value.avm.support_plan, null)
  upgrade_settings                        = try(each.value.avm.upgrade_settings, null)
  windows_profile                         = try(each.value.avm.windows_profile, null)
  windows_profile_password                = try(each.value.avm.windows_profile_password, null)
  windows_profile_password_version        = try(each.value.avm.windows_profile_password_version, null)
  workload_auto_scaler_profile            = try(each.value.avm.workload_auto_scaler_profile, null)

  tags = coalesce(try(each.value.avm.tags, null), try(each.value.tags, null))
}
