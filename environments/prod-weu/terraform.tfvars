# =====================================================================================
# Production – West Europe (WEU)
# Scope: Deploy WEU resources ONLY into the WEU workload subscription.
# =====================================================================================

subscription_id = "<WEU_SUBSCRIPTION_ID>"
tenant_id       = "<TENANT_ID>"

enable_telemetry = true

location = "westeurope"

tags = {
  environment = "prod"
}

log_analytics_workspace_configuration = {
  name               = "demo-applz-aks-prod-weu-network-law"
  resource_group_key = "weu"
  location           = "westeurope"
}

resource_groups = {
  weu = {
    name     = "demo-applz-aks-prod-weu-rg"
    location = "westeurope"
    tags = {
      environment = "prod"
    }
  }
}

key_vaults = {
  weu_shared = {
    name               = "kv-applz-aks-weu-dc3c76"
    resource_group_key = "weu"
    location           = "westeurope"
    tags = {
      environment = "prod"
      workload    = "shared-services"
    }
  }
}

storage_accounts = {
  weu_shared = {
    name               = "demoapplzaksweudc3c76"
    resource_group_key = "weu"
    location           = "westeurope"
    tags = {
      environment = "prod"
      workload    = "shared-services"
    }
  }
}

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

virtual_networks = {
  weu_spoke = {
    name               = "demo-applz-aks-prod-weu-vnet"
    location           = "westeurope"
    resource_group_key = "weu"
    address_space      = ["10.30.0.0/16"]

    subnets = {
      aks_nodes = {
        name             = "demo-applz-aks-prod-weu-sub-aks"
        address_prefixes = ["10.30.0.0/22"]
        route_table_key  = "weu_spoke_udr"
      }

      aks_apiserver = {
        name             = "demo-applz-aks-prod-weu-sub-aksapi"
        address_prefixes = ["10.30.4.0/24"]
        route_table_key  = "weu_spoke_udr"
      }

      private_endpoints = {
        name                              = "demo-applz-aks-prod-weu-sub-pe"
        address_prefixes                  = ["10.30.5.0/24"]
        private_endpoint_network_policies = "Disabled"
      }

      app_gateway = {
        name             = "demo-applz-aks-prod-weu-sub-appgw"
        address_prefixes = ["10.30.6.0/24"]
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
        name             = "demo-applz-aks-prod-weu-sub-pg"
        address_prefixes = ["10.30.7.0/24"]
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

      AzureBastionSubnet = {
        name             = "AzureBastionSubnet"
        address_prefixes = ["10.30.8.0/26"]
      }
    }

    tags = {
      environment = "prod"
      workload    = "network"
    }
  }
}

bastion_hosts = {
  weu = {
    name               = "demo-applz-aks-prod-weu-bastion"
    resource_group_key = "weu"
    location           = "westeurope"
    sku                = "Standard"
    zones              = []

    ip_configuration = {
      name = "ipconf"
      network_configuration = {
        vnet_key   = "weu_spoke"
        subnet_key = "AzureBastionSubnet"
      }
      create_public_ip       = true
      public_ip_address_name = "demo-applz-aks-prod-weu-bastion-pip"
    }

    tags = {
      environment = "prod"
      workload    = "bastion"
    }
  }
}

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

    tags = {
      environment = "prod"
      workload    = "aks"
    }
  }
}

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

    zone = "1"

    public_network_access_enabled = false

    tags = {
      environment = "prod"
      workload    = "postgres"
    }
  }
}

vhub_connectivity_definitions = {
  demo-applz-aks-prod-weu-vhub-conn = {
    vhub_resource_id = "/subscriptions/<CONNECTIVITY_SUBSCRIPTION_ID>/resourceGroups/demo-connectivity-prod-eu-rg/providers/Microsoft.Network/virtualHubs/demo-vhub-prod-eu"

    virtual_network = {
      key = "weu_spoke"
    }

    internet_security_enabled = false

    routing = {
      associated_route_table_id = "/subscriptions/<CONNECTIVITY_SUBSCRIPTION_ID>/resourceGroups/demo-connectivity-prod-eu-rg/providers/Microsoft.Network/virtualHubs/demo-vhub-prod-eu/hubRouteTables/defaultRouteTable"
      propagated_route_table = {
        route_table_ids = [
          "/subscriptions/<CONNECTIVITY_SUBSCRIPTION_ID>/resourceGroups/demo-connectivity-prod-eu-rg/providers/Microsoft.Network/virtualHubs/demo-vhub-prod-eu/hubRouteTables/defaultRouteTable"
        ]
      }
    }
  }
}
