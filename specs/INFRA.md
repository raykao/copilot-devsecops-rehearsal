# Infrastructure brief: Azure hosting for the Wealth Accounts API (v1)

> **Scaffolding target.** `infra/main.tf` has the provider, variables, a `locals` block with the shared tags and a resource group. Nothing hosts the API yet. This is a sample banking service: no real customer or BMO data.

## Goal

Host the Node accounts API (`app/`) on Azure App Service so the team has a dev environment to demo against.

## Resources to add to `infra/main.tf`

| Resource | Requirements |
|---|---|
| `azurerm_service_plan` | Linux, `B1`, in the existing resource group and location |
| `azurerm_linux_web_app` | On that plan, Node 20 LTS, HTTPS only, TLS 1.2 minimum, FTPS disabled, always on |

## Rules

- Follow the conventions already in `infra/main.tf`: names built from `local.name_prefix` with a type prefix (`rg-`, `plan-`, `app-`), tags only through `local.tags`, location and resource group taken from the existing resource group.
- Health check path is `/api/health` (see `app/server.js`).
- Start command is `node app/server.js`. The API reads its per-transfer limit from `TRANSFER_LIMIT`, so expose it as a `transfer_limit` variable (default `10000`) and pass it as an app setting.
- Output the web app's default hostname as `api_hostname`, plus `api_app_name` and `resource_group_name` (the pipeline needs them to deploy the app code).
- No secrets in the Terraform. No new providers.

## Pipeline requirements

- Pull requests: format, validate, plan (posted as a PR comment).
- `main`: apply behind the `production` environment, then deploy the API code (zip deploy) and run a **smoke check** against `https://<api_hostname>/api/health`.
- **Rollback:** a manual run of the workflow with a `rollback_ref` re-applies a known-good commit, behind the same approval.

## Standards Copilot cannot verify

Tag naming policy, approved regions, the organization's approved-actions list and private-network requirements are **not** in this repo. Copilot must list them as unverified rather than guess.

## Out of scope

- Databases, custom domains, monitoring.
- Running `terraform apply`. A human does that.
