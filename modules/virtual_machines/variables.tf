variable "virtual_machines" {
  description = "Map of virtual machines to create (AVM). Each value is a pass-through object for Azure/avm-res-compute-virtualmachine/azurerm (v0.20.0)."
  type        = any
}

variable "resource_groups" {
  description = "Resource groups map (must include name). Used when a VM provides resource_group_key instead of resource_group_name."
  type        = any
}

variable "virtual_networks" {
  description = "Virtual networks output map (from shared_services_pattern). Used to resolve subnet IDs when VM definitions use virtual_network_key/subnet_key instead of hard-coded subnet IDs."
  type        = any
  default     = {}
}

variable "location" {
  description = "Default location fallback when a VM object does not set location."
  type        = string
}

variable "tags" {
  description = "Default tags fallback when a VM object does not set tags."
  type        = map(string)
  default     = {}
}

variable "lock" {
  description = "Default lock fallback when a VM object does not set lock."
  type = object({
    kind = string
    name = optional(string, null)
  })
  default = null
}

variable "enable_telemetry" {
  description = "Default telemetry flag fallback when a VM object does not set enable_telemetry."
  type        = bool
  default     = true
}
