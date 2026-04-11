resource_group_name  = "msft-tfstate-prod-rg"
storage_account_name = "msfttfstateprod001"
container_name       = "tfstate"
key                  = "msft-applz-aks/environments/prod-sea/terraform.tfstate"

# Use Microsoft Entra ID (Azure AD) for backend auth (no access keys).
use_azuread_auth     = true
