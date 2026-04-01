terraform {
  required_version = ">= 1.9, < 2.0"

  backend "azurerm" {}

  required_providers {
    azapi = {
      source = "Azure/azapi"
      # v2.9.0 crashes on Windows during plan (provider panic). Keep on 2.x,
      # but avoid 2.9.x until that bug is resolved upstream.
      version = ">= 2.4, < 2.9.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

provider "azurerm" {
  subscription_id     = (try(trimspace(var.subscription_id), "") != "") ? var.subscription_id : null
  tenant_id           = (try(trimspace(var.tenant_id), "") != "") ? var.tenant_id : null
  storage_use_azuread = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {
  subscription_id = (try(trimspace(var.subscription_id), "") != "") ? var.subscription_id : null
  tenant_id       = (try(trimspace(var.tenant_id), "") != "") ? var.tenant_id : null
}


