variable "container_registries" {
  description = "Container Registries (ACR) to create."
  type        = any
}

variable "resource_groups" {
  description = "Resource groups map (must include name)."
  type        = any
}

variable "virtual_networks" {
  description = "Virtual networks map (must include subnets[*].resource_id)."
  type        = any
}

variable "private_dns_zones" {
  description = "Private DNS zones map (must include resource_id)."
  type        = any
}

variable "enable_telemetry" {
  description = "Pass-through flag for AVM modules that support telemetry."
  type        = bool
  default     = true
}
