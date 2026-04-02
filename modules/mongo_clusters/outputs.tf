output "mongo_cluster_ids" {
  description = "MongoDB vCore cluster resource IDs, keyed by var.mongo_clusters key."
  value       = { for k, v in module.mongo_cluster : k => v.resource_id }
}

output "mongo_cluster_names" {
  description = "MongoDB vCore cluster names, keyed by var.mongo_clusters key."
  value       = { for k, v in module.mongo_cluster : k => v.mongo_cluster_name }
}

output "private_endpoints" {
  description = "Private endpoints created for each MongoDB vCore cluster, keyed by cluster key."
  value       = { for k, v in module.mongo_cluster : k => v.private_endpoints }
}
