output "postgres_fqdns" {
  description = "PostgreSQL Flexible Server FQDNs keyed by input key."
  value       = { for k, v in module.pg : k => v.fqdn }
}
