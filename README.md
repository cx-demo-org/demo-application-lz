# demo-applz-aks

> [!IMPORTANT]
> This repository uses **Azure Verified Modules (AVM)** and is intended as a reference implementation.
> Any input values, defaults, and examples provided here are **samples only**.
> Review and adapt the configuration to meet your organization’s requirements (security, networking, naming, regions, compliance, etc.) before using it.

> [!NOTE]
> AVM modules may introduce changes over time (including breaking changes). For AVM bugs or feature requests, please raise issues with the relevant AVM module repository.

Composable landing-zone style deployment built with Azure Verified Modules (AVM) and a **map-of-objects** configuration model.

This repo is intended to be forked/copied and driven entirely from environment `.tfvars`.

## What this deploys

- Virtual Networks + Subnets 
- AKS clusters 
- Application Gateways with delegrated subnets
- PostgreSQL Flexible Server with delegated subnet + private endpoint
- Optional: VNet → Virtual WAN vHub connection 
- Bastion Server
- Key Vault
- Storage Account

## Important notes

> **Terraform version**
> The AVM AKS module requires Terraform **~> 1.12**. If your machine has an older Terraform (e.g. 1.10.x), use the repo-local Terraform binary at `.tools/terraform/1.12.2/terraform.exe`.

> **Remote state subscription**
> The prod backend config uses a dedicated state storage account in a different subscription. Ensure you have access to that subscription before running `init`.
> See `environments/prod-sea/backend.hcl` and `environments/prod-weu/backend.hcl`.

> **Secrets**
> The sample prod tfvars includes placeholder passwords (e.g. PostgreSQL admin password). Do not commit real secrets.
> Prefer injecting via pipeline secrets or a secret store.

> **AKS node resource group**
> AKS will create/manage the **node resource group** specified by `node_resource_group`. This is expected and separate from the resource groups created by Terraform.

## Repository layout

- `main.tf`: root orchestration calling internal modules
- `modules/`: internal wrappers around AVM modules
- `environments/prod-sea/terraform.tfvars`: SEA environment configuration
- `environments/prod-weu/terraform.tfvars`: WEU environment configuration
- `environments/prod-sea/backend.hcl`: SEA remote state backend settings
- `environments/prod-weu/backend.hcl`: WEU remote state backend settings

This repo intentionally uses **two isolated stacks** so SEA and WEU can run against **different subscriptions** with **different remote state keys**.

## Prerequisites

- Terraform **~> 1.12** (or use `.tools/terraform/1.12.2/terraform.exe`)
- Azure authentication (CLI login, Service Principal, or GitHub OIDC in CI)
- Permissions:
  - Deployment subscription: ability to create RGs + networking + AKS + AppGW + Postgres
  - State subscription (from backend.hcl): ability to read/write blob state

## Quickstart (prod)

If your installed Terraform is already 1.12+, you can use `terraform`. Otherwise use the local binary.

Using the local Terraform 1.12.2 binary:

- SEA stack:
  - `.tools/terraform/1.12.2/terraform.exe init -backend-config=environments/prod-sea/backend.hcl`
  - `.tools/terraform/1.12.2/terraform.exe plan -var-file=environments/prod-sea/terraform.tfvars -input=false`
  - `.tools/terraform/1.12.2/terraform.exe apply -var-file=environments/prod-sea/terraform.tfvars -input=false`

- WEU stack:
  - `.tools/terraform/1.12.2/terraform.exe init -backend-config=environments/prod-weu/backend.hcl`
  - `.tools/terraform/1.12.2/terraform.exe plan -var-file=environments/prod-weu/terraform.tfvars -input=false`
  - `.tools/terraform/1.12.2/terraform.exe apply -var-file=environments/prod-weu/terraform.tfvars -input=false`

> [!IMPORTANT]
> This repo uses placeholders (e.g. `<SEA_SUBSCRIPTION_ID>`, `<WEU_SUBSCRIPTION_ID>`, `<TENANT_ID>`, `<CONNECTIVITY_SUBSCRIPTION_ID>`, `<TFSTATE_SUBSCRIPTION_ID>`).
> Replace them with real values (or feed them via repo/environment variables) before running plan/apply.

## Configuration model

The root module is driven by these top-level maps (see `variables.tf` and the prod example tfvars):

- `resource_groups`: resource groups created by Terraform, referenced by key.
- `virtual_networks`: VNets and subnets, referenced by key.
- `aks_clusters`: AKS clusters referencing a VNet key + subnet keys.
- `application_gateways`: App Gateways referencing a VNet key + subnet key.
- `postgres_servers`: Postgres servers referencing a VNet key + delegated subnet key + private endpoints subnet key.
- `vhub_virtual_network_connections` (optional): connects a created VNet to an existing vHub.

### Key-based referencing

Cross-resource wiring is done by **keys**, not by hard-coded IDs. For example:

- AKS uses `resource_group_key`, `virtual_network_key`, `subnet_nodes_key`, `subnet_apiserver_key`
- AppGW uses `resource_group_key`, `virtual_network_key`, `subnet_key`
- Postgres uses `resource_group_key`, `virtual_network_key`, `delegated_subnet_key`, `private_endpoints_subnet_key`

## Resource group strategies

The same code supports both “single RG per region” and “multiple RGs per region”.

- **Option A (current)**: one RG per region (e.g. `sea`, `weu`) and all regional workloads target that RG.
- **Option B/C**: add more RGs (e.g. `sea_network`, `sea_shared`) and update each workload’s `resource_group_key` to point at the desired RG.

The prod tfvars includes a commented example showing exactly which keys to change:

- `virtual_networks[*].resource_group_key`
- `aks_clusters[*].resource_group_key`
- `application_gateways[*].resource_group_key`
- `postgres_servers[*].resource_group_key`
- `postgres_servers[*].private_dns_zone_resource_group_key`

## Module versions

The solution pins AVM module versions in the internal wrappers under `modules/`. Example (subject to change):

- VNet: `Azure/avm-res-network-virtualnetwork/azurerm`
- AppGW: `Azure/avm-res-network-applicationgateway/azurerm`
- Postgres: `Azure/avm-res-dbforpostgresql-flexibleserver/azurerm`
- AKS: `Azure/avm-res-containerservice-managedcluster/azurerm`
- vHub connection: `Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-network-connection`

## CI/CD (GitHub Actions)

Workflow: `.github/workflows/terraform.yml`

- **PRs and pushes to `main`** run `terraform plan` for **both** stacks (`prod-sea` and `prod-weu`).
- **Apply/Destroy** are run via `workflow_dispatch` and require you to pick a stack.

Authentication is typically done via GitHub OIDC + federated credentials. Ensure your repo/environment is configured with the required variables/secrets.

> [!NOTE]
> The workflow uses a single GitHub Actions **Environment** named `prod` for OIDC scoping. Your Entra federated credential subject should match:
> `repo:cx-demo-org/demo-application-lz:environment:prod`.

## Troubleshooting

- **"Unsupported Terraform Core version"**: install Terraform 1.12+ or use `.tools/terraform/1.12.2/terraform.exe`.
- **State backend access issues**: confirm access to the subscription and storage account in `environments/prod-sea/backend.hcl` / `environments/prod-weu/backend.hcl`.
- **AKS identity type schema validation**: ensure AzAPI provider is on a recent 2.x version (this repo allows `< 3.0`).
