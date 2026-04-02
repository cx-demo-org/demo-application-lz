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
subscription_id = null
tenant_id       = null

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
        name                 = "link-demo-applz-aks-prod-sea-vnet"
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
        name                 = "link-demo-applz-aks-prod-sea-vnet"
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
        name                 = "link-demo-applz-aks-prod-sea-vnet"
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

  storage_blob = {
    domain_name        = "privatelink.blob.core.windows.net"
    resource_group_key = "sea"

    virtual_network_links = {
      sea_spoke = {
        name                 = "link-demo-applz-aks-prod-sea-vnet"
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
  name               = "demo-applz-aks-prod-sea-network-law"
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
    name     = "demo-applz-aks-prod-sea-rg"
    location = "southeastasia"
    tags = {
      environment = "prod"
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
    name               = "kv-applz-aks-sea-demo01"
    resource_group_key = "sea"
    location           = "southeastasia"

    public_network_access_enabled = false

    private_endpoints = {
      vault = {
        name = "demo-applz-aks-prod-sea-kv-pe"
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
    name               = "demoapplzaksseademo01"
    resource_group_key = "sea"
    location           = "southeastasia"

    public_network_access_enabled = false

    private_endpoints = {
      blob = {
        name = "demo-applz-aks-prod-sea-st-pe-blob"
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
    name               = "demo-applz-aks-prod-sea-vnet-udr"
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
    name               = "demo-applz-aks-prod-sea-sub-aks-nsg"
    resource_group_key = "sea"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "network"
    }
  }

  aks_apiserver = {
    name               = "demo-applz-aks-prod-sea-sub-aksapi-nsg"
    resource_group_key = "sea"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "network"
    }
  }

  private_endpoints = {
    name               = "demo-applz-aks-prod-sea-sub-pe-nsg"
    resource_group_key = "sea"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "network"
    }
  }

  app_gateway = {
    name               = "demo-applz-aks-prod-sea-sub-appgw-nsg"
    resource_group_key = "sea"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "network"
    }
  }

  apim = {
    name               = "demo-applz-aks-prod-sea-sub-apim-nsg"
    resource_group_key = "sea"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "apim"
    }
  }

  postgresql = {
    name               = "demo-applz-aks-prod-sea-sub-pg-nsg"
    resource_group_key = "sea"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "network"
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
    name               = "demo-applz-aks-prod-sea-vnet"
    location           = "southeastasia"
    resource_group_key = "sea"
    address_space      = ["10.20.0.0/16"]

    subnets = {
      aks_nodes = {
        name                       = "demo-applz-aks-prod-sea-sub-aks"
        address_prefixes           = ["10.20.0.0/22"]
        route_table_key            = "sea_spoke_udr"
        network_security_group_key = "aks_nodes"
      }

      aks_apiserver = {
        name                       = "demo-applz-aks-prod-sea-sub-aksapi"
        address_prefixes           = ["10.20.4.0/24"]
        route_table_key            = "sea_spoke_udr"
        network_security_group_key = "aks_apiserver"
      }

      private_endpoints = {
        name                              = "demo-applz-aks-prod-sea-sub-pe"
        address_prefixes                  = ["10.20.5.0/24"]
        private_endpoint_network_policies = "Disabled"
        network_security_group_key        = "private_endpoints"
      }

      app_gateway = {
        name                       = "demo-applz-aks-prod-sea-sub-appgw"
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
        name                       = "demo-applz-aks-prod-sea-sub-apim"
        address_prefixes           = ["10.20.9.0/24"]
        network_security_group_key = "apim"
      }

      postgresql = {
        name                       = "demo-applz-aks-prod-sea-sub-pg"
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
    name                = "demo-applz-aks-prod-sea"
    location            = "southeastasia"
    resource_group_key  = "sea"
    node_resource_group = "demo-applz-aks-prod-sea-node-rg"

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
    name               = "demo-applz-aks-prod-sea-appgw"
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
api_management_services = {
  sea = {
    name               = "demo-applz-aks-prod-sea-apim"
    location           = "southeastasia"
    resource_group_key = "sea"

    publisher_email = "apim-admin@contoso.com"
    publisher_name  = "demo-applz"
    sku_name        = "Premium_1"

    public_network_access_enabled = true

    virtual_network_type = "None"

    private_endpoints_manage_dns_zone_group = true
    private_endpoints = {
      gateway = {
        name = "demo-applz-aks-prod-sea-apim-pe"
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

# -------------------------------------------------------------------------------------
# Azure Container Registry (AVM)
# -------------------------------------------------------------------------------------
# Purpose: private container image registry for AKS.
# Security posture: public access disabled + Private Endpoint + `privatelink.azurecr.io` DNS.
container_registries = {
  sea = {
    name               = "demoapplzaksseademo01acr"
    location           = "southeastasia"
    resource_group_key = "sea"

    sku                           = "Premium"
    public_network_access_enabled = false
    admin_enabled                 = false
    anonymous_pull_enabled        = false

    private_endpoints_manage_dns_zone_group = true
    private_endpoints = {
      registry = {
        name = "demo-applz-aks-prod-sea-acr-pe"
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
    name               = "demo-applz-aks-prod-sea-pg"
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
  demo-applz-aks-prod-sea-vhub-conn = {
    vhub_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/demo-connectivity-prod-sea-rg/providers/Microsoft.Network/virtualHubs/demo-vhub-prod-sea"

    virtual_network = {
      key = "sea_spoke"
    }

    internet_security_enabled = false

    routing = {
      associated_route_table_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/demo-connectivity-prod-sea-rg/providers/Microsoft.Network/virtualHubs/demo-vhub-prod-sea/hubRouteTables/defaultRouteTable"
      propagated_route_table = {
        route_table_ids = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/demo-connectivity-prod-sea-rg/providers/Microsoft.Network/virtualHubs/demo-vhub-prod-sea/hubRouteTables/defaultRouteTable"
        ]
      }
    }
  }
}
