output "aks_cluster_ids" {
  description = "AKS cluster resource IDs keyed by input key."
  value       = { for k, v in module.aks : k => v.resource_id }
}
