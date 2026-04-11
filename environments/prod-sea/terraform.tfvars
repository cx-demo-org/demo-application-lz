# =====================================================================================
# Production – Southeast Asia (SEA)
# Scope: Deploy SEA resources ONLY into the SEA workload subscription.
#
# This file is the *single source of truth* for environment-specific inputs.
# Pattern:
# - Most blocks below are maps keyed by a logical name (e.g., `sea_spoke`, `sea`).
# - Those keys are referenced by other blocks using `*_key` fields
#   (e.g., `resource_group_key`, `virtual_network_key`, `subnet_key`).
# - Keep keys stable; changing keys can cause Terraform to recreate resources.
# =====================================================================================

# -------------------------------------------------------------------------------------
# Provider / Subscription Context
# -------------------------------------------------------------------------------------
# Used by providers (AzureRM/AzAPI) to target the correct tenant/subscription.
# Must match the subscription where you intend to create resources.
subscription_id = "00000000-0000-0000-0000-000000000000"
tenant_id       = "00000000-0000-0000-0000-000000000000"

# Controls whether AVM modules emit telemetry resources.
enable_telemetry = true

# Default region used by the shared-services/network pattern.
# Individual resources can still override with their own `location`.
location = "southeastasia"

# Common tags used across most resources.
tags = {
  environment = "prod"
}

# -------------------------------------------------------------------------------------
# RBAC Examples (commented templates)
# -------------------------------------------------------------------------------------
# The `shared_services_pattern` supports RBAC in two ways:
# 1) Per-resource `role_assignments` (recommended): attach RBAC to the resource block itself.
# 2) Standalone `role_assignments`: create role assignments at arbitrary scopes.
#
# Notes:
# - `principal_id` is the Entra ID objectId of a User/Group/Service Principal.
# - Some resources (notably Key Vault + standalone role_assignments) can alternatively use
#   `managed_identity_key` to reference a UAMI created under `managed_identities`.
#
# Object IDs used in examples (placeholders for customer-facing repo):
# - User user@example.com: 00000000-0000-0000-0000-000000000000
# - Group my-group:        00000000-0000-0000-0000-000000000000
#
# Example 1 — Resource Group RBAC (resource_groups.<key>.role_assignments)
# resource_groups = {
#   sea = {
#     ...
#     role_assignments = {
#       user_contributor = {
#         role_definition_id_or_name = "Contributor"
#         principal_id               = "00000000-0000-0000-0000-000000000000"
#         principal_type             = "User"
#       }
#       group_contributor = {
#         role_definition_id_or_name = "Contributor"
#         principal_id               = "00000000-0000-0000-0000-000000000000"
#         principal_type             = "Group"
#       }
#     }
#   }
# }
#
# Example 2 — Log Analytics Workspace RBAC (log_analytics_workspace_configuration.role_assignments)
# log_analytics_workspace_configuration = {
#   ...
#   role_assignments = {
#     group_law_reader = {
#       role_definition_id_or_name = "Log Analytics Reader"
#       principal_id               = "00000000-0000-0000-0000-000000000000"
#       principal_type             = "Group"
#     }
#   }
# }
#
# Example 3 — NSG RBAC (network_security_groups.<key>.role_assignments)
# network_security_groups = {
#   vm = {
#     ...
#     role_assignments = {
#       group_nsg_network_contributor = {
#         role_definition_id_or_name = "Network Contributor"
#         principal_id               = "00000000-0000-0000-0000-000000000000"
#         principal_type             = "Group"
#       }
#     }
#   }
# }
#
# Example 4 — VNet RBAC (virtual_networks.<key>.role_assignments)
# virtual_networks = {
#   sea_spoke = {
#     ...
#     role_assignments = {
#       group_vnet_network_contributor = {
#         role_definition_id_or_name = "Network Contributor"
#         principal_id               = "00000000-0000-0000-0000-000000000000"
#         principal_type             = "Group"
#       }
#     }
#
#     # Subnet RBAC (virtual_networks.<vnet>.subnets.<subnet>.role_assignments)
#     subnets = {
#       vm = {
#         ...
#         role_assignments = {
#           user_subnet_network_contributor = {
#             role_definition_id_or_name = "Network Contributor"
#             principal_id               = "00000000-0000-0000-0000-000000000000"
#             principal_type             = "User"
#           }
#         }
#       }
#     }
#   }
# }
#
# Example 5 — Key Vault RBAC (key_vaults.<key>.role_assignments)
# key_vaults = {
#   sea_shared = {
#     ...
#     role_assignments = {
#       group_secrets_user = {
#         role_definition_id_or_name = "Key Vault Secrets User"
#         principal_id               = "00000000-0000-0000-0000-000000000000"
#         principal_type             = "Group"
#       }
#
#       # Alternate form using a managed identity created in managed_identities:
#       # app_uami_secrets_user = {
#       #   role_definition_id_or_name = "Key Vault Secrets User"
#       #   managed_identity_key       = "app"
#       # }
#     }
#   }
# }
#
# Example 6 — Storage RBAC (storage_accounts.<key>.role_assignments)
# storage_accounts = {
#   sea_shared = {
#     ...
#     role_assignments = {
#       group_blob_data_contrib = {
#         role_definition_id_or_name = "Storage Blob Data Contributor"
#         principal_id               = "00000000-0000-0000-0000-000000000000"
#         principal_type             = "Group"
#       }
#     }
#   }
# }
#
# Example 7 — Managed Identity + its role assignments (managed_identities.<key>.role_assignments)
# NOTE: This grants permissions *to the identity principal* at some target scope.
# managed_identities = {
#   app = {
#     name               = "msft-applz-aks-prod-sea-uami-app"
#     resource_group_key = "sea"
#
#     role_assignments = {
#       kv_secrets_user = {
#         role_definition_id_or_name = "Key Vault Secrets User"
#         scope                      = "/subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<kvName>"
#       }
#     }
#   }
# }
#
# Example 8 — Bastion RBAC (bastion_hosts.<key>.role_assignments)
# bastion_hosts = {
#   sea = {
#     ...
#     role_assignments = {
#       group_bastion_reader = {
#         role_definition_id_or_name = "Reader"
#         principal_id               = "00000000-0000-0000-0000-000000000000"
#         principal_type             = "Group"
#       }
#     }
#   }
# }
#
# Example 9 — Standalone RBAC at arbitrary scope (top-level role_assignments)
# role_assignments = {
#   subscription_reader = {
#     role_definition_id_or_name = "Reader"
#     scope                      = "/subscriptions/<subId>"
#     principal_id               = "00000000-0000-0000-0000-000000000000"
#     principal_type             = "Group"
#   }
# }
# -------------------------------------------------------------------------------------
# Private DNS Zones (Private Endpoint name resolution)
# -------------------------------------------------------------------------------------
# Purpose: When a Private Endpoint is created, DNS records must resolve service FQDNs
# to the Private Endpoint IP from within the VNet.
#
# Keys in this map (e.g., `acr`, `apim`) are referenced elsewhere using:
#   private_dns_zone = { keys = ["acr"] }
#
# Common zones:
# - ACR:          privatelink.azurecr.io
# - APIM Gateway: privatelink.azure-api.net
# - Key Vault:    privatelink.vaultcore.azure.net
# - Storage Blob: privatelink.blob.core.windows.net
private_dns_zones = {
  acr = {
    domain_name        = "privatelink.azurecr.io"
    resource_group_key = "sea"

    virtual_network_links = {
      sea_spoke = {
        name                 = "link-msft-applz-aks-prod-sea-vnet"
        virtual_network_key  = "sea_spoke"
        registration_enabled = false
        resolution_policy    = "Default"
        tags = {
          environment = "prod"
        }
      }
    }

    tags = {
      environment = "prod"
      workload    = "dns"
    }
  }

  apim = {
    domain_name        = "privatelink.azure-api.net"
    resource_group_key = "sea"

    virtual_network_links = {
      sea_spoke = {
        name                 = "link-msft-applz-aks-prod-sea-vnet"
        virtual_network_key  = "sea_spoke"
        registration_enabled = false
        resolution_policy    = "Default"
        tags = {
          environment = "prod"
        }
      }
    }

    tags = {
      environment = "prod"
      workload    = "dns"
    }
  }

  kv = {
    domain_name        = "privatelink.vaultcore.azure.net"
    resource_group_key = "sea"

    virtual_network_links = {
      sea_spoke = {
        name                 = "link-msft-applz-aks-prod-sea-vnet"
        virtual_network_key  = "sea_spoke"
        registration_enabled = false
    publisher_email = "apim-admin@example.com"
        tags = {
          environment = "prod"
        }
      }
    }

    tags = {
      environment = "prod"
      workload    = "dns"
    }
  }

  storage_blob = {
    domain_name        = "privatelink.blob.core.windows.net"
    resource_group_key = "sea"

    virtual_network_links = {
      sea_spoke = {
        name                 = "link-msft-applz-aks-prod-sea-vnet"
        virtual_network_key  = "sea_spoke"
        registration_enabled = false
        resolution_policy    = "Default"
        tags = {
          environment = "prod"
        }
      }
    }

    tags = {
      environment = "prod"
      workload    = "dns"
    }
  }

  # Cosmos DB for MongoDB vCore
  mongo_vcore = {
    domain_name        = "privatelink.mongocluster.cosmos.azure.com"
    resource_group_key = "sea"

    virtual_network_links = {
      sea_spoke = {
        name                 = "link-msft-applz-aks-prod-sea-vnet"
        virtual_network_key  = "sea_spoke"
        registration_enabled = false
        resolution_policy    = "Default"
        tags = {
          environment = "prod"
        }
      }
    }

    tags = {
      environment = "prod"
      workload    = "dns"
    }
  }
}

# -------------------------------------------------------------------------------------
# Log Analytics Workspace (central logging/metrics)
# -------------------------------------------------------------------------------------
# Purpose: destination for diagnostics and (optionally) AKS OMS agent logs.
log_analytics_workspace_configuration = {
  name               = "msft-applz-aks-prod-sea-network-law"
  resource_group_key = "sea"
  location           = "southeastasia"
}

# -------------------------------------------------------------------------------------
# Resource Groups
# -------------------------------------------------------------------------------------
# Purpose: lightweight containers for the environment's resources.
# Referenced by other blocks using `resource_group_key`.
resource_groups = {
  sea = {
    name     = "msft-applz-aks-prod-sea-rg"
    location = "southeastasia"
    tags = {
      environment = "prod"
    }

    role_assignments = {
      pdevadiga_contributor = {
        role_definition_id_or_name = "Contributor"
        principal_id               = "00000000-0000-0000-0000-000000000000"
        principal_type             = "User"
        description                = "Contributor access (placeholder principal)"
      }
      aksadmin_contributor = {
        role_definition_id_or_name = "Contributor"
        principal_id               = "00000000-0000-0000-0000-000000000000"
        principal_type             = "Group"
        description                = "Contributor access (placeholder principal)"
      }
    }
  }
}

# -------------------------------------------------------------------------------------
# Key Vault
# -------------------------------------------------------------------------------------
# Purpose: centralized secrets/config store.
# Security posture here is private-by-default (public access disabled + private endpoint).
key_vaults = {
  sea_shared = {
    name               = "kv-applz-aks-sea-1d70f8"
    resource_group_key = "sea"
    location           = "southeastasia"

    public_network_access_enabled = false

    role_assignments = {
      pdevadiga_secrets_user = {
        role_definition_id_or_name = "Key Vault Secrets User"
        principal_id               = "00000000-0000-0000-0000-000000000000"
        principal_type             = "User"
        description                = "Read secrets (placeholder principal)"
      }
      aksadmin_secrets_user = {
        role_definition_id_or_name = "Key Vault Secrets User"
        principal_id               = "00000000-0000-0000-0000-000000000000"
        principal_type             = "Group"
        description                = "Read secrets (placeholder principal)"
      }
    }

    private_endpoints = {
      vault = {
        name = "msft-applz-aks-prod-sea-kv-pe"
        network_configuration = {
          vnet_key   = "sea_spoke"
          subnet_key = "private_endpoints"
        }
        private_dns_zone = {
          keys = ["kv"]
        }
        tags = {
          environment = "prod"
          workload    = "shared-services"
        }
      }
    }

    tags = {
      environment = "prod"
      workload    = "shared-services"
    }
  }
}

# -------------------------------------------------------------------------------------
# Storage Account
# -------------------------------------------------------------------------------------
# Purpose: shared blob storage (data, artifacts, etc.).
# Security posture here is private-by-default (public access disabled + private endpoint).
storage_accounts = {
  sea_shared = {
    name               = "msftapplzakssea1d70f8"
    resource_group_key = "sea"
    location           = "southeastasia"

    public_network_access_enabled = false

    private_endpoints = {
      blob = {
        name = "msft-applz-aks-prod-sea-st-pe-blob"
        network_configuration = {
          vnet_key   = "sea_spoke"
          subnet_key = "private_endpoints"
        }
        subresource_name = "blob"
        private_dns_zone = {
          keys = ["storage_blob"]
        }
        tags = {
          environment = "prod"
          workload    = "shared-services"
        }
      }
    }

    # Blob containers (data plane)
    # Driven purely by TFVARS via the AVM storage account module.
    containers = {
      wfs = {
        name = "msft-sea-wfs"
      }
      datapond_dev = {
        name = "msft-sea-datapond-dev"
      }
    }

    tags = {
      environment = "prod"
      workload    = "shared-services"
    }
  }
}

# -------------------------------------------------------------------------------------
# Route Tables (UDR)
# -------------------------------------------------------------------------------------
# Purpose: required for AKS when `outbound_type = "userDefinedRouting"`.
# The AKS subnet(s) must be associated with the route table(s) *before* AKS create/update.
route_tables = {
  sea_spoke_udr = {
    name               = "msft-applz-aks-prod-sea-vnet-udr"
    resource_group_key = "sea"
    location           = "southeastasia"

    bgp_route_propagation_enabled = true

    routes = {
      default_to_firewall = {
        name                   = "default-to-fw"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.2.4.4"
      }
    }

    tags = {
      environment = "prod"
      workload    = "network"
    }
  }
}

# -------------------------------------------------------------------------------------
# Network Security Groups (NSGs)
# -------------------------------------------------------------------------------------
# Purpose: enforce subnet-level traffic rules.
# Each subnet can reference an NSG using `network_security_group_key`.
network_security_groups = {
  aks_nodes = {
    name               = "msft-applz-aks-prod-sea-sub-aks-nsg"
    resource_group_key = "sea"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "network"
    }
  }

  aks_apiserver = {
    name               = "msft-applz-aks-prod-sea-sub-aksapi-nsg"
    resource_group_key = "sea"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "network"
    }
  }

  private_endpoints = {
    name               = "msft-applz-aks-prod-sea-sub-pe-nsg"
    resource_group_key = "sea"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "network"
    }
  }

  app_gateway = {
    name               = "msft-applz-aks-prod-sea-sub-appgw-nsg"
    resource_group_key = "sea"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "network"
    }
  }

  apim = {
    name               = "msft-applz-aks-prod-sea-sub-apim-nsg"
    resource_group_key = "sea"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "apim"
    }
  }

  postgresql = {
    name               = "msft-applz-aks-prod-sea-sub-pg-nsg"
    resource_group_key = "sea"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "network"
    }
  }

  vm = {
    name               = "msft-applz-aks-prod-sea-sub-vm-nsg"
    resource_group_key = "sea"
    location           = "southeastasia"

    security_rules = {
      allow_ssh_from_58_96_249_160 = {
        name                       = "allow-ssh-from-58-96-249-160"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "58.96.249.160/32"
        destination_address_prefix = "*"
        description                = "Allow SSH to VM subnet from 58.96.249.160/32"
      }
    }

    tags = {
      environment = "prod"
      workload    = "gurobi"
    }
  }
}

# -------------------------------------------------------------------------------------
# Virtual Network + Subnets
# -------------------------------------------------------------------------------------
# Purpose: hub/spoke (spoke VNet here) with dedicated subnets for:
# - AKS nodes
# - AKS API server VNet integration (control plane subnet)
# - Private Endpoints
# - Application Gateway
# - APIM
# - PostgreSQL delegated subnet
#
# Notes:
# - Subnet delegation is required for PostgreSQL Flexible Server.
# - Private Endpoints subnet typically has `private_endpoint_network_policies = "Disabled"`.
virtual_networks = {
  sea_spoke = {
    name               = "msft-applz-aks-prod-sea-vnet"
    location           = "southeastasia"
    resource_group_key = "sea"
    address_space      = ["10.20.0.0/16"]

    subnets = {
      aks_nodes = {
        name                       = "msft-applz-aks-prod-sea-sub-aks"
        address_prefixes           = ["10.20.0.0/22"]
        route_table_key            = "sea_spoke_udr"
        network_security_group_key = "aks_nodes"
      }

      aks_apiserver = {
        name                       = "msft-applz-aks-prod-sea-sub-aksapi"
        address_prefixes           = ["10.20.4.0/24"]
        route_table_key            = "sea_spoke_udr"
        network_security_group_key = "aks_apiserver"

        # Required for the AKS API server VNet integration subnet.
        # Prevents Azure from rejecting updates with SubnetMissingRequiredDelegation.
        delegations = [
          {
            name = "aks-delegation"
            service_delegation = {
              name = "Microsoft.ContainerService/managedClusters"
            }
          }
        ]
      }

      private_endpoints = {
        name                              = "msft-applz-aks-prod-sea-sub-pe"
        address_prefixes                  = ["10.20.5.0/24"]
        private_endpoint_network_policies = "Disabled"
        network_security_group_key        = "private_endpoints"
      }

      app_gateway = {
        name                       = "msft-applz-aks-prod-sea-sub-appgw"
        address_prefixes           = ["10.20.6.0/24"]
        network_security_group_key = "app_gateway"
        delegations = [
          {
            name = "appgw"
            service_delegation = {
              name = "Microsoft.Network/applicationGateways"
            }
          }
        ]
      }

      api_management = {
        name                       = "msft-applz-aks-prod-sea-sub-apim"
        address_prefixes           = ["10.20.9.0/24"]
        network_security_group_key = "apim"
      }

      vm = {
        name                       = "msft-applz-aks-prod-sea-sub-vm"
        address_prefixes           = ["10.20.8.0/24"]
        network_security_group_key = "vm"
      }

      postgresql = {
        name                       = "msft-applz-aks-prod-sea-sub-pg"
        address_prefixes           = ["10.20.7.0/24"]
        network_security_group_key = "postgresql"
        service_endpoints_with_location = [
          {
            service   = "Microsoft.Storage"
            locations = ["southeastasia", "eastasia"]
          }
        ]
        delegations = [
          {
            name = "postgres-flex"
            service_delegation = {
              name = "Microsoft.DBforPostgreSQL/flexibleServers"
            }
          }
        ]
      }

    }

    tags = {
      environment = "prod"
      workload    = "network"
    }
  }
}

# -------------------------------------------------------------------------------------
# AKS Cluster (AVM managed cluster)
# -------------------------------------------------------------------------------------
# Purpose: Kubernetes cluster deployed into BYO VNet/subnets.
#
# Private cluster behavior:
# - The AKS wrapper defaults `private_cluster = true` and configures API server VNet integration.
# - GitHub Actions plan/apply should show `enablePrivateCluster: true` after our AKS fix.
#
# Egress routing:
# - `outbound_type = "userDefinedRouting"` uses the UDR route table on the AKS subnet.
# - Azure currently rejects UDR when AKS `publicNetworkAccess` is set to `Disabled`.
#   We set `avm.public_network_access = "Enabled"` while still enabling private cluster.
aks_clusters = {
  sea = {
    name                = "msft-applz-aks-prod-sea"
    location            = "southeastasia"
    resource_group_key  = "sea"
    node_resource_group = "msft-applz-aks-prod-sea-node-rg"

    virtual_network_key  = "sea_spoke"
    subnet_nodes_key     = "aks_nodes"
    subnet_apiserver_key = "aks_apiserver"

    network_profile = {
      outbound_type = "userDefinedRouting"
    }

    default_agent_pool = {
      vm_size = "Standard_D2s_v6"
    }

    enable_oms_agent = true

    avm = {
      public_network_access = "Enabled"
      azure_monitor_profile = {
        metrics = {
          enabled = true
        }
      }

      # OPTIONAL: Additional user node pools (uncomment based on application team requirement)
      #
      # Matches Sandbox sizing:
      # - Node Pool — General:         x86pool / Standard_D4s_v3 / 4 nodes
      # - Node Pool — ML/Optimization: mlpool  / Standard_E16s_v5 / 1 node
      #
      # agent_pools = {
      #   x86pool = {
      #     name   = "x86pool"
      #     mode   = "User"
      #     vm_size = "Standard_D4s_v3"
      #     count_of = 4
      #     enable_auto_scaling = false
      #   }
      #
      #   mlpool = {
      #     name   = "mlpool"
      #     mode   = "User"
      #     vm_size = "Standard_E16s_v5"
      #     count_of = 1
      #     enable_auto_scaling = false
      #   }
      # }
    }

    tags = {
      environment = "prod"
      workload    = "aks"
    }
  }
}

# -------------------------------------------------------------------------------------
# Application Gateway (AVM)
# -------------------------------------------------------------------------------------
# Purpose: L7 ingress/load-balancing. This configuration is private-only (no public IP).
application_gateways = {
  sea = {
    name               = "msft-applz-aks-prod-sea-appgw"
    location           = "southeastasia"
    resource_group_key = "sea"

    virtual_network_key = "sea_spoke"
    subnet_key          = "app_gateway"

    frontend_ports = {
      http = {
        name = "http"
        port = 80
      }
    }

    backend_address_pools = {
      default = {
        name         = "default"
        ip_addresses = ["10.20.0.4"]
      }
    }

    backend_http_settings = {
      default = {
        name                  = "default"
        port                  = 80
        protocol              = "Http"
        cookie_based_affinity = "Disabled"
      }
    }

    public_ip_address_configuration = {
      create_public_ip_enabled = false
    }

    frontend_ip_configuration_private = {
      name                          = "private-frontend"
      private_ip_address_allocation = "Static"
      private_ip_address            = "10.20.6.10"
    }

    http_listeners = {
      listener = {
        name                           = "listener"
        frontend_port_name             = "http"
        frontend_ip_configuration_name = "private-frontend"
      }
    }

    request_routing_rules = {
      rule = {
        name                       = "rule"
        rule_type                  = "Basic"
        http_listener_name         = "listener"
        backend_address_pool_name  = "default"
        backend_http_settings_name = "default"
        priority                   = 100
      }
    }

    tags = {
      environment = "prod"
      workload    = "appgw"
    }
  }
}

# -------------------------------------------------------------------------------------
# API Management (AVM)
# -------------------------------------------------------------------------------------
# Purpose: API gateway/management plane.
#
# Important:
# - We use an *inbound Gateway private endpoint* (private connectivity) while APIM itself
#   is not deployed as internal VNet APIM (virtual_network_type = "None").


# -------------------------------------------------------------------------------------
# TEMPORARILY DISABLED: API Management (AVM)
# -------------------------------------------------------------------------------------
# APIM can take a long time to update (up to ~80 minutes) and will fail terraform reads
# during certain maintenance windows. Leave the configuration below for later re-enable.
api_management_services = {}

/*
api_management_services = {
  sea = {
    name               = "msft-applz-aks-prod-sea-apim"
    location           = "southeastasia"
    resource_group_key = "sea"

    publisher_email = "apim-admin@example.com"
    publisher_name  = "msft-applz"
    sku_name        = "Premium_1"

    public_network_access_enabled = true

    virtual_network_type = "None"

    private_endpoints_manage_dns_zone_group = true
    private_endpoints = {
      gateway = {
        name = "msft-applz-aks-prod-sea-apim-pe"
        network_configuration = {
          virtual_network_key = "sea_spoke"
          subnet_key          = "private_endpoints"
        }
        private_dns_zone = {
          keys = ["apim"]
        }
        tags = {
          environment = "prod"
          workload    = "apim"
        }
      }
    }

    tags = {
      environment = "prod"
      workload    = "apim"
    }
  }
}
*/

# -------------------------------------------------------------------------------------
# Azure Container Registry (AVM)
# -------------------------------------------------------------------------------------
# Purpose: private container image registry for AKS.
# Security posture: public access disabled + Private Endpoint + `privatelink.azurecr.io` DNS.
container_registries = {
  sea = {
    name               = "msftapplzakssea1d70f8acr"
    location           = "southeastasia"
    resource_group_key = "sea"

    sku                           = "Premium"
    public_network_access_enabled = false
    admin_enabled                 = false
    anonymous_pull_enabled        = false

    private_endpoints_manage_dns_zone_group = true
    private_endpoints = {
      registry = {
        name = "msft-applz-aks-prod-sea-acr-pe"
        network_configuration = {
          virtual_network_key = "sea_spoke"
          subnet_key          = "private_endpoints"
        }
        private_dns_zone = {
          keys = ["acr"]
        }
        tags = {
          environment = "prod"
          workload    = "acr"
        }
      }
    }

    tags = {
      environment = "prod"
      workload    = "acr"
    }
  }
}

# -------------------------------------------------------------------------------------
# Cosmos DB for MongoDB vCore clusters (AVM)
# -------------------------------------------------------------------------------------
# Purpose: managed MongoDB-compatible database (vCore-based) with private endpoint support.
#
# Notes:
# - Do NOT commit real passwords. Inject `administrator_login_password` via secret store.
# - When `public_network_access = "Disabled"`, you typically want a private endpoint.
# - This repo expects you to model everything via tfvars; uncomment and adjust as needed.
#
mongo_clusters = {
  sea = {
    # Required
    name                         = "msft-applz-aks-prod-sea-mongo"
    location                     = "southeastasia"
    resource_group_key           = "sea"
    administrator_login          = "mongoadmin"
    administrator_login_password = null

    # Optional
    public_network_access = "Disabled"
    enable_ha             = true
    compute_tier          = "M30"
    node_count            = 3
    storage_size_gb       = 128
    server_version        = "7.0"

    private_endpoints_manage_dns_zone_group = true
    private_endpoints = {
      pe = {
        name = "msft-applz-aks-prod-sea-mongo-pe"

        network_configuration = {
          virtual_network_key = "sea_spoke"
          subnet_key          = "private_endpoints"
        }

        private_dns_zone = {
          keys = ["mongo_vcore"]
        }

        tags = {
          environment = "prod"
          workload    = "mongo"
        }
      }
    }

    tags = {
      environment = "prod"
      workload    = "mongo"
    }
  }
}

# -------------------------------------------------------------------------------------
# PostgreSQL Flexible Server (wrapper around AVM)
# -------------------------------------------------------------------------------------
# Purpose: managed relational DB.
#
# Networking:
# - `delegated_subnet_key` must refer to a subnet delegated to
#   `Microsoft.DBforPostgreSQL/flexibleServers`.
# - `private_endpoints_subnet_key` is where the DB private endpoint NIC is placed.
# - `private_dns_zone_resource_group_key` is where the postgres private DNS zone lives.
#
# Credentials:
# - Do NOT commit real passwords. Use secret stores (GitHub Actions secrets/vars, TF Cloud variables,
#   or Key Vault data sources) to inject `administrator_password`.
postgres_servers = {
  sea = {
    name               = "msft-applz-aks-prod-sea-pg"
    location           = "southeastasia"
    resource_group_key = "sea"

    virtual_network_key          = "sea_spoke"
    delegated_subnet_key         = "postgresql"
    private_endpoints_subnet_key = "private_endpoints"

    private_dns_zone_resource_group_key = "sea"

    administrator_login    = "pgadmin"
    administrator_password = "ReplaceMe-UseSecretStore-2026!"

    server_version = "16"
    sku_name       = "GP_Standard_D2s_v3"
    storage_mb     = 131072

    zone = "1"

    public_network_access_enabled = false

    # Application databases
    databases = {
      dagster = {
        name = "dagster"
      }
      iceberg = {
        name = "iceberg"
      }
      superset = {
        name = "superset"
      }
      datahub = {
        name = "datahub"
      }
    }

    tags = {
      environment = "prod"
      workload    = "postgres"
    }
  }
}

# -------------------------------------------------------------------------------------
# vWAN Hub Connectivity
# -------------------------------------------------------------------------------------
# Purpose: connect this spoke VNet to the central Virtual WAN hub.
vhub_connectivity_definitions = {
  msft-applz-aks-prod-sea-vhub-conn = {
    vhub_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/msft-connectivity-prod-sea-rg/providers/Microsoft.Network/virtualHubs/msft-vhub-prod-sea"

    virtual_network = {
      key = "sea_spoke"
    }

    internet_security_enabled = false

    routing = {
      associated_route_table_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/msft-connectivity-prod-sea-rg/providers/Microsoft.Network/virtualHubs/msft-vhub-prod-sea/hubRouteTables/defaultRouteTable"
      propagated_route_table = {
        route_table_ids = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/msft-connectivity-prod-sea-rg/providers/Microsoft.Network/virtualHubs/msft-vhub-prod-sea/hubRouteTables/defaultRouteTable"
        ]
      }
    }
  }
}

# -------------------------------------------------------------------------------------
# Virtual Machines
# -------------------------------------------------------------------------------------
# Purpose: optional IaaS VMs using Azure/avm-res-compute-virtualmachine/azurerm.
virtual_machines = {
  gurobi = {
    # Requested VM name (Linux allows up to 64 chars).
    name               = "msft-applz-aks-prod-gurobi-sea"
    location           = "southeastasia"
    resource_group_key = "sea"

    # Required by the upstream module; set to null if deploying to a region without zones.
    zone = "1"

    # Reference the subnet created in virtual_networks.sea_spoke.subnets.vm
    # (Resolved to a real subnet resource ID inside the virtual_machines wrapper.)
    virtual_network_key = "sea_spoke"
    subnet_key          = "vm"

    # Minimum NIC config: provide the target subnet resource ID.
    # Replace the placeholder with the real subnet ID you want this VM in (e.g. the "aks_nodes" subnet, or a dedicated "vm" subnet).
    network_interfaces = {
      nic1 = {
        name = "msft-applz-aks-prod-gurobi-sea-nic1"
        ip_configurations = {
          ipconfig1 = {
            name                     = "ipconfig1"
            create_public_ip_address = true
            public_ip_address_name   = "msft-applz-aks-prod-gurobi-sea-pip"
          }
        }
      }
    }

    os_type  = "Linux"
    sku_size = "Standard_D2ds_v5"

    # Requires subscription feature Microsoft.Compute/EncryptionAtHost; disable for this subscription.
    encryption_at_host_enabled = false

    source_image_reference = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    }

    tags = {
      environment = "prod"
      workload    = "gurobi"
    }
  }
}
