variable "postgres_servers" {
  description = "PostgreSQL Flexible Servers to create."
  type        = any
}

variable "resource_groups" {
  description = "Resource groups map (must include name and resource_id)."
  type        = any
}

variable "virtual_networks" {
  description = "Virtual networks map (must include name/resource_id/subnets[*].resource_id)."
  type        = any
}

variable "enable_telemetry" {
  description = "Pass-through flag for AVM modules that support telemetry."
  type        = bool
  default     = true
}
