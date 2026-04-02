# =====================================================================================
# Production – West Europe (WEU)
# Scope: Deploy WEU resources ONLY into the WEU workload subscription.
#
# This file is the *single source of truth* for environment-specific inputs.
# Pattern:
# - Most blocks below are maps keyed by a logical name (e.g., `weu_spoke`, `weu`).
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
location = "westeurope"

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
    resource_group_key = "weu"

    virtual_network_links = {
      weu_spoke = {
        name                 = "link-demo-applz-aks-prod-weu-vnet"
        virtual_network_key  = "weu_spoke"
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
    resource_group_key = "weu"

    virtual_network_links = {
      weu_spoke = {
        name                 = "link-demo-applz-aks-prod-weu-vnet"
        virtual_network_key  = "weu_spoke"
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
    resource_group_key = "weu"

    virtual_network_links = {
      weu_spoke = {
        name                 = "link-demo-applz-aks-prod-weu-vnet"
        virtual_network_key  = "weu_spoke"
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
    resource_group_key = "weu"

    virtual_network_links = {
      weu_spoke = {
        name                 = "link-demo-applz-aks-prod-weu-vnet"
        virtual_network_key  = "weu_spoke"
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
    resource_group_key = "weu"

    virtual_network_links = {
      weu_spoke = {
        name                 = "link-demo-applz-aks-prod-weu-vnet"
        virtual_network_key  = "weu_spoke"
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
  name               = "demo-applz-aks-prod-weu-network-law"
  resource_group_key = "weu"
  location           = "westeurope"
}

# -------------------------------------------------------------------------------------
# Resource Groups
# -------------------------------------------------------------------------------------
# Purpose: lightweight containers for the environment's resources.
# Referenced by other blocks using `resource_group_key`.
resource_groups = {
  weu = {
    name     = "demo-applz-aks-prod-weu-rg"
    location = "westeurope"
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
  weu_shared = {
    name               = "kv-applz-aks-weu-dc3c76"
    resource_group_key = "weu"
    location           = "westeurope"

    public_network_access_enabled = false

    private_endpoints = {
      vault = {
        name = "demo-applz-aks-prod-weu-kv-pe"
        network_configuration = {
          vnet_key   = "weu_spoke"
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
  weu_shared = {
    name               = "demoapplzaksweudc3c76"
    resource_group_key = "weu"
    location           = "westeurope"

    public_network_access_enabled = false

    private_endpoints = {
      blob = {
        name = "demo-applz-aks-prod-weu-st-pe-blob"
        network_configuration = {
          vnet_key   = "weu_spoke"
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
        name = "demo-weu-wfs"
      }
      datapond_dev = {
        name = "demo-weu-datapond-dev"
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
  weu_spoke_udr = {
    name               = "demo-applz-aks-prod-weu-vnet-udr"
    resource_group_key = "weu"
    location           = "westeurope"

    bgp_route_propagation_enabled = true

    routes = {
      default_to_firewall = {
        name                   = "default-to-fw"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "172.16.4.4"
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
    name               = "demo-applz-aks-prod-weu-sub-aks-nsg"
    resource_group_key = "weu"
    location           = "westeurope"
    tags = {
      environment = "prod"
      workload    = "network"
    }
  }

  aks_apiserver = {
    name               = "demo-applz-aks-prod-weu-sub-aksapi-nsg"
    resource_group_key = "weu"
    location           = "westeurope"
    tags = {
      environment = "prod"
      workload    = "network"
    }
  }

  private_endpoints = {
    name               = "demo-applz-aks-prod-weu-sub-pe-nsg"
    resource_group_key = "weu"
    location           = "westeurope"
    tags = {
      environment = "prod"
      workload    = "network"
    }
  }

  app_gateway = {
    name               = "demo-applz-aks-prod-weu-sub-appgw-nsg"
    resource_group_key = "weu"
    location           = "westeurope"
    tags = {
      environment = "prod"
      workload    = "network"
    }
  }

  apim = {
    name               = "demo-applz-aks-prod-weu-sub-apim-nsg"
    resource_group_key = "weu"
    location           = "westeurope"
    tags = {
      environment = "prod"
      workload    = "apim"
    }
  }

  postgresql = {
    name               = "demo-applz-aks-prod-weu-sub-pg-nsg"
    resource_group_key = "weu"
    location           = "westeurope"
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
  weu_spoke = {
    name               = "demo-applz-aks-prod-weu-vnet"
    location           = "westeurope"
    resource_group_key = "weu"
    address_space      = ["10.30.0.0/16"]

    subnets = {
      aks_nodes = {
        name                       = "demo-applz-aks-prod-weu-sub-aks"
        address_prefixes           = ["10.30.0.0/22"]
        route_table_key            = "weu_spoke_udr"
        network_security_group_key = "aks_nodes"
      }

      aks_apiserver = {
        name                       = "demo-applz-aks-prod-weu-sub-aksapi"
        address_prefixes           = ["10.30.4.0/24"]
        route_table_key            = "weu_spoke_udr"
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
        name                              = "demo-applz-aks-prod-weu-sub-pe"
        address_prefixes                  = ["10.30.5.0/24"]
        private_endpoint_network_policies = "Disabled"
        network_security_group_key        = "private_endpoints"
      }

      app_gateway = {
        name                       = "demo-applz-aks-prod-weu-sub-appgw"
        address_prefixes           = ["10.30.6.0/24"]
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
        name                       = "demo-applz-aks-prod-weu-sub-apim"
        address_prefixes           = ["10.30.9.0/24"]
        network_security_group_key = "apim"
      }

      postgresql = {
        name                       = "demo-applz-aks-prod-weu-sub-pg"
        address_prefixes           = ["10.30.7.0/24"]
        network_security_group_key = "postgresql"
        service_endpoints_with_location = [
          {
            service   = "Microsoft.Storage"
            locations = ["westeurope", "northeurope"]
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
  weu = {
    name                = "demo-applz-aks-prod-weu"
    location            = "westeurope"
    resource_group_key  = "weu"
    node_resource_group = "demo-applz-aks-prod-weu-node-rg"

    virtual_network_key  = "weu_spoke"
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
  weu = {
    name               = "demo-applz-aks-prod-weu-appgw"
    location           = "westeurope"
    resource_group_key = "weu"

    virtual_network_key = "weu_spoke"
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
        ip_addresses = ["10.30.0.4"]
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
      private_ip_address            = "10.30.6.10"
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
  weu = {
    name               = "demo-applz-aks-prod-weu-apim"
    location           = "westeurope"
    resource_group_key = "weu"

    publisher_email = "apim-admin@contoso.com"
    publisher_name  = "demo-applz"
    sku_name        = "Premium_1"

    public_network_access_enabled = true

    virtual_network_type = "None"

    private_endpoints_manage_dns_zone_group = true
    private_endpoints = {
      gateway = {
        name = "demo-applz-aks-prod-weu-apim-pe"
        network_configuration = {
          virtual_network_key = "weu_spoke"
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
  weu = {
    name               = "demoapplzaksweudc3c76acr"
    location           = "westeurope"
    resource_group_key = "weu"

    sku                           = "Premium"
    public_network_access_enabled = false
    admin_enabled                 = false
    anonymous_pull_enabled        = false

    private_endpoints_manage_dns_zone_group = true
    private_endpoints = {
      registry = {
        name = "demo-applz-aks-prod-weu-acr-pe"
        network_configuration = {
          virtual_network_key = "weu_spoke"
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
  weu = {
    # Required
    name                         = "demo-applz-aks-prod-weu-mongo"
    location                     = "westeurope"
    resource_group_key           = "weu"
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
        name = "demo-applz-aks-prod-weu-mongo-pe"

        network_configuration = {
          virtual_network_key = "weu_spoke"
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
#
# Zoning:
# - Zone is pinned; changing it later generally fails unless doing an HA zone swap.
postgres_servers = {
  weu = {
    name               = "demo-applz-aks-prod-weu-pg"
    location           = "westeurope"
    resource_group_key = "weu"

    virtual_network_key          = "weu_spoke"
    delegated_subnet_key         = "postgresql"
    private_endpoints_subnet_key = "private_endpoints"

    private_dns_zone_resource_group_key = "weu"

    administrator_login    = "pgadmin"
    administrator_password = "ReplaceMe-UseSecretStore-2026!"

    server_version = "16"
    sku_name       = "GP_Standard_D2s_v3"
    storage_mb     = 131072

    # Pin zone to the already-created server's zone. Changing zone post-create
    # fails unless using HA zone swap.
    zone = "3"

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
  demo-applz-aks-prod-weu-vhub-conn = {
    vhub_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/demo-connectivity-prod-eu-rg/providers/Microsoft.Network/virtualHubs/demo-vhub-prod-eu"

    virtual_network = {
      key = "weu_spoke"
    }

    internet_security_enabled = false

    routing = {
      associated_route_table_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/demo-connectivity-prod-eu-rg/providers/Microsoft.Network/virtualHubs/demo-vhub-prod-eu/hubRouteTables/defaultRouteTable"
      propagated_route_table = {
        route_table_ids = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/demo-connectivity-prod-eu-rg/providers/Microsoft.Network/virtualHubs/demo-vhub-prod-eu/hubRouteTables/defaultRouteTable"
        ]
      }
    }
  }
}
