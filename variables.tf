variable "subscription_id" {
  description = "Subscription ID used by the AzureRM/AzAPI providers. If null/empty, Terraform will rely on ambient authentication context."
  type        = string
  default     = null
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the AzureRM/AzAPI providers. If null/empty, Terraform will rely on ambient authentication context."
  type        = string
  default     = null
}

variable "location" {
  type        = string
  description = "Default Azure region used by the shared virtual network pattern module. Individual resources can override per-object."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags applied by the shared virtual network pattern module."
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = "Optional resource lock applied by the shared virtual network pattern module."
}

variable "byo_log_analytics_workspace" {
  type = object({
    resource_id = string
    location    = string
  })
  default     = null
  description = "Optional: bring-your-own Log Analytics workspace for the shared virtual network pattern module."
}

variable "log_analytics_workspace_configuration" {
  type = object({
    name               = string
    resource_group_key = string
    location           = optional(string)
    sku                = optional(string, "PerGB2018")
    retention_in_days  = optional(number, 30)
    tags               = optional(map(string), {})
    role_assignments   = optional(any, {})
    private_endpoints  = optional(any, {})
  })
  default     = null
  description = "Optional: configuration for auto-creating a Log Analytics workspace via the shared virtual network pattern module. Required if byo_log_analytics_workspace is null."
}

variable "resource_groups" {
  description = "Map of resource groups to create. Keys are referenced by other objects (resource_group_key)."
  type = map(object({
    name             = string
    location         = optional(string)
    tags             = optional(map(string), {})
    lock             = optional(any)
    role_assignments = optional(any, {})
  }))
}

variable "virtual_networks" {
  description = "Map of spoke VNets to create via the shared virtual network pattern module."
  type = map(object({
    name               = string
    address_space      = set(string)
    resource_group_key = string
    location           = optional(string)
    dns_servers        = optional(list(string))
    ddos_protection_plan = optional(object({
      resource_id = string
      enable      = bool
    }))
    encryption = optional(object({
      enabled     = bool
      enforcement = string
    }))
    tags     = optional(map(string), {})
    peerings = optional(any, {})
    subnets = optional(map(object({
      name                       = string
      address_prefix             = optional(string)
      address_prefixes           = optional(list(string))
      network_security_group_key = optional(string)
      route_table_key            = optional(string)
      service_endpoints_with_location = optional(list(object({
        service   = string
        locations = optional(list(string), ["*"])
      })), [])
      delegations = optional(list(object({
        name = string
        service_delegation = object({
          name = string
        })
      })), [])
      default_outbound_access_enabled   = optional(bool, false)
      private_endpoint_network_policies = optional(string, "Enabled")
      role_assignments                  = optional(any, {})
    })), {})
    role_assignments    = optional(any, {})
    diagnostic_settings = optional(any, {})
  }))

  validation {
    condition = alltrue([
      for vk, vnet in var.virtual_networks : alltrue([
        for sk, subnet in vnet.subnets : (subnet.address_prefix != null) != (subnet.address_prefixes != null)
      ])
    ])
    error_message = "Each subnet must define exactly one of address_prefix or address_prefixes, not both."
  }
}

variable "network_security_groups" {
  description = "Optional: NSGs to create via the shared virtual network pattern module."
  type        = any
  default     = {}
}

variable "route_tables" {
  description = "Optional: route tables to create via the shared virtual network pattern module."
  type = map(object({
    name                          = string
    resource_group_key            = string
    location                      = optional(string)
    bgp_route_propagation_enabled = optional(bool, true)
    routes = optional(map(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "private_dns_zones" {
  description = "Optional: private DNS zones to create via the shared virtual network pattern module."
  type        = any
  default     = {}
}

variable "byo_private_dns_zone_links" {
  description = "Optional: links to BYO private DNS zones via the shared virtual network pattern module."
  type        = any
  default     = {}
}

variable "managed_identities" {
  description = "Optional: managed identities to create via the shared virtual network pattern module."
  type        = any
  default     = {}
}

variable "key_vaults" {
  description = "Optional: key vaults to create via the shared virtual network pattern module."
  type        = any
  default     = {}
}

variable "role_assignments" {
  description = "Optional: standalone role assignments to create via the shared virtual network pattern module."
  type        = any
  default     = {}
}

variable "vhub_connectivity_definitions" {
  description = "Optional: map of vWAN hub connections created via the shared virtual network pattern module."
  type = map(object({
    vhub_resource_id = string
    virtual_network = object({
      key         = optional(string)
      resource_id = optional(string)
    })
    internet_security_enabled = optional(bool, true)
    routing = optional(object({
      associated_route_table_id = string
      propagated_route_table = optional(object({
        route_table_ids = optional(list(string), [])
        labels          = optional(list(string), [])
      }))
      static_vnet_route = optional(object({
        name                = optional(string)
        address_prefixes    = optional(list(string), [])
        next_hop_ip_address = optional(string)
      }))
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.vhub_connectivity_definitions : (v.virtual_network.key != null) != (v.virtual_network.resource_id != null)])
    error_message = "Each vhub_connectivity_definition must set exactly one of virtual_network.key or virtual_network.resource_id."
  }
}

variable "bastion_hosts" {
  description = "Optional: Bastion hosts to create via the shared virtual network pattern module."
  type        = any
  default     = {}
}

variable "storage_accounts" {
  description = "Optional: storage accounts to create via the shared virtual network pattern module."
  type        = any
  default     = {}
}

variable "flowlog_configuration" {
  description = "Optional: Network Watcher / flow logs configuration for the shared virtual network pattern module."
  type        = any
  default     = null
}

variable "aks_clusters" {
  description = "Map of AKS clusters to create (AVM managed cluster) and attach to the created VNets/subnets."
  type = map(object({
    name               = string
    location           = string
    resource_group_key = string

    node_resource_group = string

    virtual_network_key  = string
    subnet_nodes_key     = string
    subnet_apiserver_key = string

    dns_prefix = optional(string, null)

    aad_admin_group_object_ids = optional(list(string), null)
    enable_azure_rbac          = optional(bool, true)
    tenant_id                  = optional(string, null)

    private_cluster = optional(bool, true)

    default_agent_pool = optional(object({
      name                = optional(string, "system")
      vm_size             = optional(string, "Standard_DS2_v2")
      enable_auto_scaling = optional(bool, true)
      min_count           = optional(number, 2)
      max_count           = optional(number, 4)
      max_pods            = optional(number, 30)
      upgrade_max_surge   = optional(string, "10%")
    }), {})

    network_profile = optional(object({
      dns_service_ip      = optional(string, "10.10.200.10")
      service_cidr        = optional(string, "10.10.200.0/24")
      pod_cidr            = optional(string, "10.244.0.0/16")
      network_plugin      = optional(string, "azure")
      network_plugin_mode = optional(string, "overlay")
      network_policy      = optional(string, "azure")
      outbound_type       = optional(string, "userDefinedRouting")
    }), {})

    enable_oms_agent      = optional(bool, true)
    law_name              = optional(string, null)
    law_retention_in_days = optional(number, 30)
    law_sku               = optional(string, "PerGB2018")

    identity_name = optional(string, null)

    avm = optional(object({
      # Optional overrides for the underlying AVM module inputs.
      # These map 1:1 to variables in `Azure/avm-res-containerservice-managedcluster/azurerm` (v0.4.2).
      location  = optional(string, null)
      name      = optional(string, null)
      parent_id = optional(string, null)

      aad_profile = optional(object({
        admin_group_object_ids = optional(list(string))
        client_app_id          = optional(string)
        enable_azure_rbac      = optional(bool)
        managed                = optional(bool)
        server_app_id          = optional(string)
        server_app_secret      = optional(string)
        tenant_id              = optional(string)
      }), null)

      addon_profile_azure_policy = optional(object({
        config  = optional(map(string))
        enabled = bool
      }), null)

      addon_profile_confidential_computing      = optional(any, null)
      addon_profile_ingress_application_gateway = optional(any, null)
      addon_profile_key_vault_secrets_provider  = optional(any, null)
      addon_profile_oms_agent                   = optional(any, null)
      addon_profiles_extra                      = optional(any, null)

      agent_pools                   = optional(any, null)
      agentpool_timeouts            = optional(any, null)
      ai_toolchain_operator_profile = optional(any, null)

      api_server_access_profile = optional(object({
        authorized_ip_ranges               = optional(list(string))
        disable_run_command                = optional(bool)
        enable_private_cluster             = optional(bool)
        enable_private_cluster_public_fqdn = optional(bool)
        enable_vnet_integration            = optional(bool)
        private_dns_zone                   = optional(string)
        subnet_id                          = optional(string)
      }), null)

      auto_scaler_profile   = optional(any, null)
      auto_upgrade_profile  = optional(any, null)
      azure_monitor_profile = optional(any, null)
      bootstrap_profile     = optional(any, null)
      cluster_timeouts      = optional(any, null)

      create_agentpools_before_destroy = optional(bool, null)

      default_agent_pool  = optional(any, null)
      diagnostic_settings = optional(any, null)

      disable_local_accounts = optional(bool, null)
      disk_encryption_set_id = optional(string, null)
      dns_prefix             = optional(string, null)
      enable_rbac            = optional(bool, null)
      enable_telemetry       = optional(bool, null)
      extended_location      = optional(any, null)
      fqdn_subdomain         = optional(string, null)
      http_proxy_config      = optional(any, null)
      identity_profile       = optional(any, null)
      ingress_profile        = optional(any, null)
      kind                   = optional(string, null)
      kubernetes_version     = optional(string, null)
      linux_profile          = optional(any, null)
      lock                   = optional(any, null)

      managed_identities                      = optional(any, null)
      metrics_profile                         = optional(any, null)
      network_profile                         = optional(any, null)
      node_provisioning_profile               = optional(any, null)
      node_resource_group                     = optional(string, null)
      node_resource_group_profile             = optional(any, null)
      oidc_issuer_profile                     = optional(any, null)
      pod_identity_profile                    = optional(any, null)
      private_endpoints                       = optional(any, null)
      private_endpoints_manage_dns_zone_group = optional(bool, null)
      private_link_resources                  = optional(any, null)
      public_network_access                   = optional(string, null)
      role_assignments                        = optional(any, null)
      security_profile                        = optional(any, null)
      service_mesh_profile                    = optional(any, null)
      service_principal_profile               = optional(any, null)
      sku                                     = optional(any, null)
      storage_profile                         = optional(any, null)
      support_plan                            = optional(string, null)
      tags                                    = optional(map(string), null)
      upgrade_settings                        = optional(any, null)
      windows_profile                         = optional(any, null)
      windows_profile_password                = optional(string, null)
      windows_profile_password_version        = optional(string, null)
      workload_auto_scaler_profile            = optional(any, null)
    }), {})

    tags = optional(map(string), null)
  }))
}

variable "application_gateways" {
  description = "Map of Application Gateways to create (AVM)."
  type = map(object({
    name               = string
    location           = string
    resource_group_key = string

    virtual_network_key = string
    subnet_key          = string

    gateway_ip_configuration_name = optional(string, null)

    backend_address_pools = map(object({
      name         = string
      fqdns        = optional(set(string))
      ip_addresses = optional(set(string))
    }))

    backend_http_settings = map(object({
      name                                 = string
      port                                 = number
      protocol                             = string
      cookie_based_affinity                = optional(string, "Disabled")
      dedicated_backend_connection_enabled = optional(bool, false)
      request_timeout                      = optional(number, 30)
      pick_host_name_from_backend_address  = optional(bool)
      host_name                            = optional(string)
      path                                 = optional(string)
      probe_name                           = optional(string)
      affinity_cookie_name                 = optional(string)
      trusted_root_certificate_names       = optional(list(string))
      authentication_certificate = optional(list(object({
        name = string
      })), null)
      connection_draining = optional(object({
        drain_timeout_sec          = number
        enable_connection_draining = bool
      }), null)
    }))

    frontend_ports = map(object({
      name = string
      port = number
    }))

    http_listeners = map(object({
      name                           = string
      frontend_port_name             = string
      frontend_ip_configuration_name = optional(string)
      firewall_policy_id             = optional(string)
      require_sni                    = optional(bool)
      host_name                      = optional(string)
      host_names                     = optional(list(string))
      ssl_certificate_name           = optional(string)
      ssl_profile_name               = optional(string)
      custom_error_configuration = optional(list(object({
        status_code           = string
        custom_error_page_url = string
      })), null)
    }))

    request_routing_rules = map(object({
      name                        = string
      rule_type                   = string
      http_listener_name          = string
      backend_address_pool_name   = string
      backend_http_settings_name  = string
      priority                    = number
      url_path_map_name           = optional(string)
      redirect_configuration_name = optional(string)
      rewrite_rule_set_name       = optional(string)
    }))

    sku = optional(object({
      name     = string
      tier     = string
      capacity = optional(number)
      }), {
      name     = "Standard_v2"
      tier     = "Standard_v2"
      capacity = 2
    })

    public_ip_address_configuration = optional(object({
      resource_group_name              = optional(string, null)
      location                         = optional(string, null)
      create_public_ip_enabled         = optional(bool, true)
      public_ip_name                   = optional(string, null)
      public_ip_resource_id            = optional(string, null)
      allocation_method                = optional(string, "Static")
      ddos_protection_mode             = optional(string, "VirtualNetworkInherited")
      ddos_protection_plan_resource_id = optional(string, null)
      domain_name_label                = optional(string, null)
      idle_timeout_in_minutes          = optional(number, 4)
      ip_version                       = optional(string, "IPv4")
      public_ip_prefix_resource_id     = optional(string, null)
      reverse_fqdn                     = optional(string, null)
      sku                              = optional(string, "Standard")
      sku_tier                         = optional(string, "Regional")
      tags                             = optional(map(any), {})
      zones                            = optional(list(string), null)
    }), {})

    app_gateway_waf_policy_resource_id = optional(string, null)
    authentication_certificate         = optional(map(object({ name = string, data = string })), null)
    autoscale_configuration = optional(object({
      min_capacity = optional(number, 1)
      max_capacity = optional(number, 2)
    }), null)
    custom_error_configuration = optional(map(object({
      custom_error_page_url = string
      status_code           = string
    })), null)

    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})

    fips_enabled                      = optional(bool, null)
    force_firewall_policy_association = optional(bool, true)

    frontend_ip_configuration_private = optional(object({
      name                            = optional(string, null)
      private_ip_address              = optional(string, null)
      private_ip_address_allocation   = optional(string, null)
      private_link_configuration_name = optional(string, null)
    }), {})

    frontend_ip_configuration_public_name = optional(string, null)
    global = optional(object({
      request_buffering_enabled  = bool
      response_buffering_enabled = bool
    }), null)
    http2_enable = optional(bool, true)

    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)

    managed_identities = optional(object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
    }), {})

    private_link_configuration = optional(set(object({
      name = string
      ip_configuration = list(object({
        name                          = string
        primary                       = bool
        private_ip_address            = optional(string, null)
        private_ip_address_allocation = string
        subnet_id                     = string
      }))
    })), null)

    probe_configurations = optional(map(object({
      name                                      = string
      host                                      = optional(string, null)
      interval                                  = number
      timeout                                   = number
      unhealthy_threshold                       = number
      protocol                                  = string
      port                                      = optional(number, null)
      path                                      = string
      pick_host_name_from_backend_http_settings = optional(bool, null)
      minimum_servers                           = optional(number, null)
      match = optional(object({
        body        = optional(string, null)
        status_code = optional(list(string), null)
      }), null)
    })), null)

    redirect_configuration = optional(map(object({
      name                 = string
      redirect_type        = string
      include_path         = optional(bool, null)
      include_query_string = optional(bool, null)
      target_listener_name = optional(string, null)
      target_url           = optional(string, null)
    })), null)

    rewrite_rule_set = optional(map(object({
      name = string
      rewrite_rules = optional(map(object({
        name          = string
        rule_sequence = number
        conditions = optional(map(object({
          ignore_case = optional(bool, null)
          negate      = optional(bool, null)
          pattern     = string
          variable    = string
        })), null)
        request_header_configurations = optional(map(object({
          header_name  = string
          header_value = string
        })), null)
        response_header_configurations = optional(map(object({
          header_name  = string
          header_value = string
        })), null)
        url = optional(object({
          components   = optional(string, null)
          path         = optional(string, null)
          query_string = optional(string, null)
          reroute      = optional(bool, null)
        }), null)
      })), null)
    })), null)

    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})

    ssl_certificates = optional(map(object({
      name                = string
      data                = optional(string, null)
      password            = optional(string, null)
      key_vault_secret_id = optional(string, null)
    })), null)

    ssl_policy = optional(object({
      cipher_suites        = optional(list(string), null)
      disabled_protocols   = optional(list(string), null)
      min_protocol_version = optional(string, "TLSv1_2")
      policy_name          = optional(string, null)
      policy_type          = optional(string, null)
    }), null)

    ssl_profile = optional(map(object({
      name                                 = string
      trusted_client_certificate_names     = optional(list(string), null)
      verify_client_cert_issuer_dn         = optional(bool, false)
      verify_client_certificate_revocation = optional(string, "OCSP")
      ssl_policy = optional(object({
        cipher_suites        = optional(list(string), null)
        disabled_protocols   = optional(list(string), null)
        min_protocol_version = optional(string, "TLSv1_2")
        policy_name          = optional(string, null)
        policy_type          = optional(string, null)
      }), null)
    })), null)

    timeouts = optional(object({
      create = optional(string, null)
      delete = optional(string, null)
      read   = optional(string, null)
      update = optional(string, null)
    }), null)

    trusted_client_certificate = optional(map(object({
      name = string
      data = string
    })), null)

    trusted_root_certificate = optional(map(object({
      name                = string
      data                = optional(string, null)
      key_vault_secret_id = optional(string, null)
    })), null)

    url_path_map_configurations = optional(map(object({
      name                                = string
      default_redirect_configuration_name = optional(string, null)
      default_rewrite_rule_set_name       = optional(string, null)
      default_backend_http_settings_name  = optional(string, null)
      default_backend_address_pool_name   = optional(string, null)
      path_rules = map(object({
        name                        = string
        paths                       = list(string)
        backend_address_pool_name   = optional(string, null)
        backend_http_settings_name  = optional(string, null)
        redirect_configuration_name = optional(string, null)
        rewrite_rule_set_name       = optional(string, null)
        firewall_policy_id          = optional(string, null)
      }))
    })), null)

    waf_configuration = optional(object({
      enabled                  = bool
      file_upload_limit_mb     = optional(number, null)
      firewall_mode            = string
      max_request_body_size_kb = optional(number, null)
      request_body_check       = optional(bool, null)
      rule_set_type            = optional(string, null)
      rule_set_version         = string
      disabled_rule_group = optional(list(object({
        rule_group_name = string
        rules           = optional(list(number), null)
      })), null)
      exclusion = optional(list(object({
        match_variable          = string
        selector                = optional(string, null)
        selector_match_operator = optional(string, null)
      })), null)
    }), null)

    zones = optional(set(string), ["1", "2", "3"])

    tags = optional(map(string), null)
  }))
}

variable "api_management_services" {
  description = "Map of API Management services to create (AVM)."
  type = map(object({
    name                = string
    location            = string
    resource_group_key  = optional(string, null)
    resource_group_name = optional(string, null)

    publisher_email = string

    additional_location = optional(any, [])
    api_version_sets    = optional(any, {})
    apis                = optional(any, {})
    certificate         = optional(any, [])

    client_certificate_enabled = optional(bool, false)
    delegation                 = optional(any, null)
    gateway_disabled           = optional(bool, false)
    hostname_configuration     = optional(any, null)

    publisher_name                = optional(string, null)
    sku_name                      = optional(string, "Developer_1")
    zones                         = optional(list(string), null)
    public_network_access_enabled = optional(bool, true)

    min_api_version           = optional(string, null)
    named_values              = optional(any, {})
    notification_sender_email = optional(string, null)
    policy                    = optional(any, null)
    products                  = optional(any, {})
    protocols                 = optional(any, null)
    public_ip_address_id      = optional(string, null)
    security                  = optional(any, null)
    sign_in                   = optional(any, null)
    sign_up                   = optional(any, null)
    subscriptions             = optional(any, {})
    tenant_access             = optional(any, null)
    virtual_network_subnet_id = optional(string, null)

    virtual_network_type = optional(string, "None")
    virtual_network_configuration = optional(object({
      virtual_network_key = optional(string, null)
      subnet_key          = optional(string, null)
      subnet_resource_id  = optional(string, null)
    }), null)

    enable_telemetry = optional(bool, null)

    diagnostic_settings                     = optional(any, {})
    managed_identities                      = optional(any, {})
    lock                                    = optional(any, null)
    role_assignments                        = optional(any, {})
    private_endpoints                       = optional(any, {})
    private_endpoints_manage_dns_zone_group = optional(bool, true)

    tags = optional(map(string), null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.api_management_services : (
        ((try(v.resource_group_key, null) != null) != (try(v.resource_group_name, null) != null)) &&
        (
          v.virtual_network_configuration == null ? true : (
            (
              try(v.virtual_network_configuration.subnet_resource_id, null) != null &&
              try(v.virtual_network_configuration.virtual_network_key, null) == null &&
              try(v.virtual_network_configuration.subnet_key, null) == null
              ) || (
              try(v.virtual_network_configuration.subnet_resource_id, null) == null &&
              try(v.virtual_network_configuration.virtual_network_key, null) != null &&
              try(v.virtual_network_configuration.subnet_key, null) != null
            )
          )
        ) &&
        (
          try(v.virtual_network_subnet_id, null) != null ? v.virtual_network_configuration == null : true
        ) &&
        (
          try(v.virtual_network_type, "None") == "None" ? true : (
            try(v.virtual_network_subnet_id, null) != null || v.virtual_network_configuration != null
          )
        )
      )
    ])
    error_message = "Each api_management_service must set exactly one of resource_group_key or resource_group_name. Also set either virtual_network_subnet_id or virtual_network_configuration (not both). If virtual_network_type is not 'None', a subnet must be provided."
  }
}

variable "container_registries" {
  description = "Map of Azure Container Registries (ACR) to create (AVM)."
  type = map(object({
    # Required
    name                = string
    location            = string
    resource_group_key  = optional(string, null)
    resource_group_name = optional(string, null)

    # Optional (AVM Inputs (26) minus required above)
    admin_enabled              = optional(bool, false)
    anonymous_pull_enabled     = optional(bool, false)
    customer_managed_key       = optional(any, null)
    data_endpoint_enabled      = optional(bool, false)
    diagnostic_settings        = optional(any, {})
    enable_telemetry           = optional(bool, null)
    enable_trust_policy        = optional(bool, false)
    export_policy_enabled      = optional(bool, true)
    georeplications            = optional(any, [])
    lock                       = optional(any, null)
    managed_identities         = optional(any, {})
    network_rule_bypass_option = optional(string, null)
    network_rule_set           = optional(any, null)

    private_endpoints = optional(map(object({
      name = optional(string, null)

      role_assignments = optional(any, {})

      lock = optional(any, null)
      tags = optional(map(string), null)

      # Either set subnet_resource_id directly OR provide network_configuration.
      subnet_resource_id = optional(string, null)
      network_configuration = optional(object({
        subnet_resource_id  = optional(string, null)
        virtual_network_key = optional(string, null)
        subnet_key          = optional(string, null)
      }), null)

      private_dns_zone_group_name   = optional(string, "default")
      private_dns_zone_resource_ids = optional(set(string), [])
      private_dns_zone = optional(object({
        keys = optional(list(string), [])
      }), null)

      application_security_group_associations = optional(map(string), {})
      private_service_connection_name         = optional(string, null)
      network_interface_name                  = optional(string, null)
      location                                = optional(string, null)
      resource_group_name                     = optional(string, null)
      ip_configurations                       = optional(any, {})
    })), {})

    private_endpoints_manage_dns_zone_group = optional(bool, true)
    public_network_access_enabled           = optional(bool, true)
    quarantine_policy_enabled               = optional(bool, false)
    retention_policy_in_days                = optional(number, 7)
    role_assignments                        = optional(any, {})
    scope_maps                              = optional(any, {})
    sku                                     = optional(string, "Premium")
    tags                                    = optional(map(string), null)
    zone_redundancy_enabled                 = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.container_registries : ((try(v.resource_group_key, null) != null) != (try(v.resource_group_name, null) != null))
    ])
    error_message = "Each container_registry must set exactly one of resource_group_key or resource_group_name."
  }
}

variable "postgres_servers" {
  description = "Map of PostgreSQL Flexible Servers to create (AVM) with delegated subnet + private endpoint in a dedicated subnet."
  type = map(object({
    name               = string
    location           = string
    resource_group_key = string

    virtual_network_key          = string
    delegated_subnet_key         = string
    private_endpoints_subnet_key = string

    private_dns_zone_resource_group_key = optional(string, null)

    administrator_login               = optional(string, null)
    administrator_password            = optional(string, null)
    administrator_password_wo         = optional(string, null)
    administrator_password_wo_version = optional(string, null)

    authentication = optional(object({
      active_directory_auth_enabled = optional(bool)
      password_auth_enabled         = optional(bool)
      tenant_id                     = optional(string)
    }), null)

    sku_name       = optional(string, null)
    server_version = optional(string, null)
    storage_mb     = optional(number, null)
    storage_tier   = optional(string, null)
    zone           = optional(string, null)

    public_network_access_enabled = optional(bool, false)

    databases = optional(map(object({
      name      = string
      charset   = optional(string)
      collation = optional(string)
    })), {})

    firewall_rules = optional(map(object({
      name             = string
      start_ip_address = string
      end_ip_address   = string
    })), {})

    tags = optional(map(string), null)
  }))
}

variable "enable_telemetry" {
  description = "Pass-through flag for AVM modules that support telemetry."
  type        = bool
  default     = true
}
