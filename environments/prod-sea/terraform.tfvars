# =====================================================================================
# Production – Southeast Asia (SEA)
# Scope: Deploy SEA resources ONLY into the SEA workload subscription.
# =====================================================================================

subscription_id = "<SEA_SUBSCRIPTION_ID>"
tenant_id       = "<TENANT_ID>"

enable_telemetry = true

location = "southeastasia"

tags = {
  environment = "prod"
}

log_analytics_workspace_configuration = {
  name               = "demo-applz-aks-prod-sea-network-law"
  resource_group_key = "sea"
  location           = "southeastasia"
}

resource_groups = {
  sea = {
    name     = "demo-applz-aks-prod-sea-rg"
    location = "southeastasia"
    tags = {
      environment = "prod"
    }
  }
}

key_vaults = {
  sea_shared = {
    name               = "kv-applz-aks-sea-1d70f8"
    resource_group_key = "sea"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "shared-services"
    }
  }
}

storage_accounts = {
  sea_shared = {
    name               = "demoapplzakssea1d70f8"
    resource_group_key = "sea"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "shared-services"
    }
  }
}

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

virtual_networks = {
  sea_spoke = {
    name               = "demo-applz-aks-prod-sea-vnet"
    location           = "southeastasia"
    resource_group_key = "sea"
    address_space      = ["10.20.0.0/16"]

    subnets = {
      aks_nodes = {
        name             = "demo-applz-aks-prod-sea-sub-aks"
        address_prefixes = ["10.20.0.0/22"]
        route_table_key  = "sea_spoke_udr"
      }

      aks_apiserver = {
        name             = "demo-applz-aks-prod-sea-sub-aksapi"
        address_prefixes = ["10.20.4.0/24"]
        route_table_key  = "sea_spoke_udr"
      }

      private_endpoints = {
        name                              = "demo-applz-aks-prod-sea-sub-pe"
        address_prefixes                  = ["10.20.5.0/24"]
        private_endpoint_network_policies = "Disabled"
      }

      app_gateway = {
        name             = "demo-applz-aks-prod-sea-sub-appgw"
        address_prefixes = ["10.20.6.0/24"]
        delegations = [
          {
            name = "appgw"
            service_delegation = {
              name = "Microsoft.Network/applicationGateways"
            }
          }
        ]
      }

      postgresql = {
        name             = "demo-applz-aks-prod-sea-sub-pg"
        address_prefixes = ["10.20.7.0/24"]
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

      AzureBastionSubnet = {
        name             = "AzureBastionSubnet"
        address_prefixes = ["10.20.8.0/26"]
      }
    }

    tags = {
      environment = "prod"
      workload    = "network"
    }
  }
}

bastion_hosts = {
  sea = {
    name               = "demo-applz-aks-prod-sea-bastion"
    resource_group_key = "sea"
    location           = "southeastasia"
    sku                = "Standard"
    zones              = []

    ip_configuration = {
      name = "ipconf"
      network_configuration = {
        vnet_key   = "sea_spoke"
        subnet_key = "AzureBastionSubnet"
      }
      create_public_ip       = true
      public_ip_address_name = "demo-applz-aks-prod-sea-bastion-pip"
    }

    tags = {
      environment = "prod"
      workload    = "bastion"
    }
  }
}

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

    tags = {
      environment = "prod"
      workload    = "aks"
    }
  }
}

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

vhub_connectivity_definitions = {
  demo-applz-aks-prod-sea-vhub-conn = {
    vhub_resource_id = "/subscriptions/<CONNECTIVITY_SUBSCRIPTION_ID>/resourceGroups/demo-connectivity-prod-sea-rg/providers/Microsoft.Network/virtualHubs/demo-vhub-prod-sea"

    virtual_network = {
      key = "sea_spoke"
    }

    internet_security_enabled = false

    routing = {
      associated_route_table_id = "/subscriptions/<CONNECTIVITY_SUBSCRIPTION_ID>/resourceGroups/demo-connectivity-prod-sea-rg/providers/Microsoft.Network/virtualHubs/demo-vhub-prod-sea/hubRouteTables/defaultRouteTable"
      propagated_route_table = {
        route_table_ids = [
          "/subscriptions/<CONNECTIVITY_SUBSCRIPTION_ID>/resourceGroups/demo-connectivity-prod-sea-rg/providers/Microsoft.Network/virtualHubs/demo-vhub-prod-sea/hubRouteTables/defaultRouteTable"
        ]
      }
    }
  }
}
