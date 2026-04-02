variable "mongo_clusters" {
  description = "Map of Cosmos DB for MongoDB (vCore) clusters to create (AVM). Exposes all upstream module inputs (24) via a map-of-objects model."

  type = map(object({
    # Required (upstream required inputs)
    name                         = string
    location                     = string
    administrator_login          = string
    administrator_login_password = optional(string, null)

    # Resource group targeting (upstream requires resource_group_name)
    # Provide exactly one of resource_group_key or resource_group_name.
    resource_group_key  = optional(string, null)
    resource_group_name = optional(string, null)

    # Optional (upstream optional inputs)
    backup_policy_type = optional(string, "Continuous7Days")
    compute_tier       = optional(string, "M30")

    customer_managed_key = optional(object({
      key_vault_resource_id = string
      key_name              = string
      key_version           = optional(string, null)
      user_assigned_identity = optional(object({
        resource_id = string
      }), null)
    }), null)

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

    enable_ha        = optional(bool, null)
    enable_telemetry = optional(bool, null)

    firewall_rules = optional(list(object({
      name     = string
      start_ip = string
      end_ip   = string
    })), [])

    ha_mode = optional(string, "Disabled")

    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)

    managed_identities = optional(object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
    }), {})

    node_count = optional(number, null)

    private_endpoints = optional(map(object({
      name = optional(string, null)

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

      lock = optional(object({
        kind = string
        name = optional(string, null)
      }), null)

      tags = optional(map(string), null)

      # Either set subnet_resource_id directly, or provide network_configuration.
      subnet_resource_id = optional(string, null)
      network_configuration = optional(object({
        virtual_network_key = optional(string, null)
        subnet_key          = optional(string, null)
        subnet_resource_id  = optional(string, null)
      }), null)

      private_dns_zone_group_name   = optional(string, "default")
      private_dns_zone_resource_ids = optional(set(string), [])
      private_dns_zone = optional(object({
        keys         = optional(list(string), [])
        resource_ids = optional(set(string), [])
      }), null)

      application_security_group_associations = optional(map(string), {})
      private_service_connection_name         = optional(string, null)
      network_interface_name                  = optional(string, null)
      location                                = optional(string, null)
      resource_group_name                     = optional(string, null)

      ip_configurations = optional(map(object({
        name               = string
        private_ip_address = string
      })), {})
    })), {})

    private_endpoints_manage_dns_zone_group = optional(bool, true)

    public_network_access = optional(string, "Disabled")

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

    server_version  = optional(string, "7.0")
    shard_count     = optional(number, 1)
    storage_size_gb = optional(number, 32)

    tags = optional(map(string), null)
  }))

  default = {}

  validation {
    condition = alltrue([
      for k, v in var.mongo_clusters : (
        (try(v.resource_group_key, null) != null) != (try(v.resource_group_name, null) != null)
      )
    ])
    error_message = "Each mongo_clusters entry must set exactly one of resource_group_key or resource_group_name."
  }
}

variable "mongo_cluster_admin_passwords" {
  description = "Sensitive override for Mongo vCore administrator passwords, keyed by mongo_clusters key."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "resource_groups" {
  description = "Resource groups output from the shared services pattern module (key -> {resource_id,name})."
  type = map(object({
    resource_id = string
    name        = string
  }))
}

variable "virtual_networks" {
  description = "Virtual networks output from the shared services pattern module (key -> vnet + subnets)."
  type        = any
  default     = {}
}

variable "private_dns_zones" {
  description = "Private DNS zones output from the shared services pattern module (key -> {resource_id,name})."
  type = map(object({
    resource_id = string
    name        = string
  }))
  default = {}
}

variable "enable_telemetry" {
  description = "Controls AVM telemetry for this wrapper (defaults to root enable_telemetry)."
  type        = bool
  default     = true
}
