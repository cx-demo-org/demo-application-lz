module "virtual_networks" {
  source = "./modules/shared_services_pattern"

  location = var.location
  tags     = var.tags
  lock     = var.lock

  resource_groups                       = var.resource_groups
  byo_log_analytics_workspace           = var.byo_log_analytics_workspace
  log_analytics_workspace_configuration = var.log_analytics_workspace_configuration

  network_security_groups       = var.network_security_groups
  route_tables                  = var.route_tables
  virtual_networks              = var.virtual_networks
  private_dns_zones             = var.private_dns_zones
  byo_private_dns_zone_links    = var.byo_private_dns_zone_links
  managed_identities            = var.managed_identities
  key_vaults                    = var.key_vaults
  role_assignments              = var.role_assignments
  vhub_connectivity_definitions = var.vhub_connectivity_definitions
  bastion_hosts                 = var.bastion_hosts
  storage_accounts              = var.storage_accounts
  flowlog_configuration         = var.flowlog_configuration
}

module "postgres_servers" {
  source = "./modules/postgres_servers"

  postgres_servers = var.postgres_servers
  resource_groups  = module.virtual_networks.resource_groups
  virtual_networks = module.virtual_networks.virtual_networks
  enable_telemetry = var.enable_telemetry
}

module "aks" {
  source = "./modules/aks"

  # Ensure UDR route table associations (created in the networking module)
  # exist before AKS is created with `outbound_type = userDefinedRouting`.
  depends_on = [module.virtual_networks]

  aks_clusters     = var.aks_clusters
  tenant_id        = var.tenant_id
  resource_groups  = module.virtual_networks.resource_groups
  virtual_networks = module.virtual_networks.virtual_networks
  enable_telemetry = var.enable_telemetry
}

module "application_gateways" {
  source = "./modules/application_gateways"

  application_gateways = var.application_gateways
  resource_groups      = module.virtual_networks.resource_groups
  virtual_networks     = module.virtual_networks.virtual_networks
  enable_telemetry     = var.enable_telemetry
}

module "api_management_services" {
  source = "./modules/api_management_services"

  api_management_services = var.api_management_services
  resource_groups         = module.virtual_networks.resource_groups
  virtual_networks        = module.virtual_networks.virtual_networks
  private_dns_zones       = module.virtual_networks.private_dns_zones
  enable_telemetry        = var.enable_telemetry
}

module "container_registries" {
  source = "./modules/container_registries"

  container_registries = var.container_registries
  resource_groups      = module.virtual_networks.resource_groups
  virtual_networks     = module.virtual_networks.virtual_networks
  private_dns_zones    = module.virtual_networks.private_dns_zones
  enable_telemetry     = var.enable_telemetry
}

module "mongo_clusters" {
  source = "./modules/mongo_clusters"

  mongo_clusters                = var.mongo_clusters
  mongo_cluster_admin_passwords = var.mongo_cluster_admin_passwords
  resource_groups               = module.virtual_networks.resource_groups
  virtual_networks              = module.virtual_networks.virtual_networks
  private_dns_zones             = module.virtual_networks.private_dns_zones
  enable_telemetry              = var.enable_telemetry
}

