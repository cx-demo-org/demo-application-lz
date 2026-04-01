variable "aks_clusters" {
  description = "AKS clusters map."
  type        = any
}

variable "resource_groups" {
  description = "Resource groups map (must include name and resource_id)."
  type        = any
}

variable "virtual_networks" {
  description = "Virtual networks map (must include subnets[*].resource_id)."
  type        = any
}

variable "tenant_id" {
  description = "Tenant ID used as fallback for AAD profile."
  type        = string
  default     = null
}

variable "enable_telemetry" {
  description = "Pass-through flag for AVM modules that support telemetry."
  type        = bool
  default     = true
}
