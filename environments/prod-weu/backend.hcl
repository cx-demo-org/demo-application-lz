resource_group_name  = "demo-tfstate-prod-rg"
storage_account_name = "demotfstateprod001"
subscription_id      = "<TFSTATE_SUBSCRIPTION_ID>"
container_name       = "tfstate"
key                  = "demo-applz-aks/environments/prod-weu/terraform.tfstate"

# Use Microsoft Entra ID (Azure AD) for backend auth (no access keys).
use_azuread_auth     = true
