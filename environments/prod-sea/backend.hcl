resource_group_name  = "demo-tfstate-prod-rg"
storage_account_name = "demotfstateprod001"
subscription_id      = "00000000-0000-0000-0000-000000000000"
container_name       = "tfstate"
key                  = "demo-applz-aks/environments/prod-sea/terraform.tfstate"

# Use Microsoft Entra ID (Azure AD) for backend auth (no access keys).
use_azuread_auth     = true
