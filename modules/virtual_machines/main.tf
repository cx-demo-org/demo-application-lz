module "virtual_machine" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.20.0"

  for_each = var.virtual_machines

  # -----------------
  # Required inputs
  # -----------------
  location = try(each.value.location, var.location)
  name     = each.value.name

  # If an IP configuration does not set private_ip_subnet_resource_id, allow the VM object
  # to provide virtual_network_key + subnet_key (consistent with other wrapper modules).
  network_interfaces = {
    for nic_key, nic in each.value.network_interfaces : nic_key => merge(nic, {
      ip_configurations = {
        for ipconfig_key, ipconfig in nic.ip_configurations : ipconfig_key => merge(ipconfig, {
          private_ip_subnet_resource_id = coalesce(
            try(ipconfig.private_ip_subnet_resource_id, null),
            try(var.virtual_networks[each.value.virtual_network_key].subnets[each.value.subnet_key].resource_id, null)
          )
        })
      }
    })
  }

  resource_group_name = coalesce(
    try(each.value.resource_group_name, null),
    try(var.resource_groups[each.value.resource_group_key].name, null)
  )

  # Required by upstream module to intentionally select zones; may be null in regions without zones.
  zone = try(each.value.zone, null)

  # -----------------
  # Optional inputs (pass-through)
  # Defaults mirror upstream module defaults (v0.20.0)
  # -----------------
  account_credentials = try(each.value.account_credentials, {})

  additional_unattend_contents                           = try(each.value.additional_unattend_contents, [])
  allow_extension_operations                             = try(each.value.allow_extension_operations, true)
  availability_set_resource_id                           = try(each.value.availability_set_resource_id, null)
  azure_backup_configurations                            = try(each.value.azure_backup_configurations, {})
  boot_diagnostics                                       = try(each.value.boot_diagnostics, false)
  boot_diagnostics_storage_account_uri                   = try(each.value.boot_diagnostics_storage_account_uri, null)
  bypass_platform_safety_checks_on_user_schedule_enabled = try(each.value.bypass_platform_safety_checks_on_user_schedule_enabled, false)
  capacity_reservation_group_resource_id                 = try(each.value.capacity_reservation_group_resource_id, null)
  computer_name                                          = try(each.value.computer_name, null)
  custom_data                                            = try(each.value.custom_data, null)
  data_disk_existing_disks                               = try(each.value.data_disk_existing_disks, {})
  data_disk_managed_disks                                = try(each.value.data_disk_managed_disks, {})
  dedicated_host_group_resource_id                       = try(each.value.dedicated_host_group_resource_id, null)
  dedicated_host_resource_id                             = try(each.value.dedicated_host_resource_id, null)
  diagnostic_settings                                    = try(each.value.diagnostic_settings, {})
  disk_controller_type                                   = try(each.value.disk_controller_type, null)
  edge_zone                                              = try(each.value.edge_zone, null)
  enable_automatic_updates                               = try(each.value.enable_automatic_updates, true)
  enable_telemetry                                       = try(each.value.enable_telemetry, var.enable_telemetry)
  encryption_at_host_enabled                             = try(each.value.encryption_at_host_enabled, true)
  eviction_policy                                        = try(each.value.eviction_policy, null)
  extensions                                             = try(each.value.extensions, {})
  extensions_time_budget                                 = try(each.value.extensions_time_budget, "PT1H30M")
  gallery_applications                                   = try(each.value.gallery_applications, {})
  hotpatching_enabled                                    = try(each.value.hotpatching_enabled, false)
  license_type                                           = try(each.value.license_type, null)
  lock                                                   = try(each.value.lock, var.lock)
  maintenance_configuration_resource_ids                 = try(each.value.maintenance_configuration_resource_ids, {})
  managed_identities                                     = try(each.value.managed_identities, {})
  max_bid_price                                          = try(each.value.max_bid_price, -1)

  os_disk = try(each.value.os_disk, {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  })

  os_type               = try(each.value.os_type, "Windows")
  patch_assessment_mode = try(each.value.patch_assessment_mode, "ImageDefault")
  patch_mode            = try(each.value.patch_mode, null)

  plan = try(each.value.plan, null)

  platform_fault_domain                 = try(each.value.platform_fault_domain, null)
  priority                              = try(each.value.priority, "Regular")
  provision_vm_agent                    = try(each.value.provision_vm_agent, true)
  proximity_placement_group_resource_id = try(each.value.proximity_placement_group_resource_id, null)

  public_ip_configuration_details = try(each.value.public_ip_configuration_details, {
    allocation_method       = "Static"
    ddos_protection_mode    = "VirtualNetworkInherited"
    idle_timeout_in_minutes = 30
    ip_version              = "IPv4"
    sku                     = "Standard"
    sku_tier                = "Regional"
  })

  reboot_setting                           = try(each.value.reboot_setting, null)
  role_assignments                         = try(each.value.role_assignments, {})
  role_assignments_system_managed_identity = try(each.value.role_assignments_system_managed_identity, {})
  run_commands                             = try(each.value.run_commands, {})
  run_commands_secrets                     = try(each.value.run_commands_secrets, {})
  secrets                                  = try(each.value.secrets, [])
  secure_boot_enabled                      = try(each.value.secure_boot_enabled, null)
  shutdown_schedules                       = try(each.value.shutdown_schedules, {})
  sku_size                                 = try(each.value.sku_size, "Standard_D2ds_v5")

  source_image_reference = try(each.value.source_image_reference, {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  })

  source_image_resource_id              = try(each.value.source_image_resource_id, null)
  tags                                  = try(each.value.tags, var.tags)
  termination_notification              = try(each.value.termination_notification, null)
  timeouts                              = try(each.value.timeouts, {})
  timezone                              = try(each.value.timezone, null)
  user_data                             = try(each.value.user_data, null)
  virtual_machine_scale_set_resource_id = try(each.value.virtual_machine_scale_set_resource_id, null)
  vm_additional_capabilities            = try(each.value.vm_additional_capabilities, null)
  vtpm_enabled                          = try(each.value.vtpm_enabled, null)
  winrm_listeners                       = try(each.value.winrm_listeners, [])

  # -----------------
  # Deprecated upstream variables (still part of Inputs (72))
  # -----------------
  admin_password                            = try(each.value.admin_password, null)
  admin_ssh_keys                            = try(each.value.admin_ssh_keys, [])
  admin_username                            = try(each.value.admin_username, "azureuser")
  disable_password_authentication           = try(each.value.disable_password_authentication, true)
  generate_admin_password_or_ssh_key        = try(each.value.generate_admin_password_or_ssh_key, true)
  generated_secrets_key_vault_secret_config = try(each.value.generated_secrets_key_vault_secret_config, null)
}
