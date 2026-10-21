# Saved answers

Show these if Copilot is slow or wanders. They live under `docs/`, which is excluded from Copilot search, so they never leak into a live answer.

## `/explain-plan` on `infra/samples/plan-forced-replacement.txt`

**Summary:** 3 resources to add and 3 to destroy. Nothing is updated in place.

**Cause:** `location` on `azurerm_resource_group.main` changes from `canadacentral` to `eastus`. A resource group's location can't change in place, so Terraform marks it `forces replacement`. The service plan and web app live in that group, so they are replaced too.

**Risk:** the API is down while the old resources are destroyed and the new ones come up. App settings, deployment slots and certificates are lost unless they are in code.

**Unverified:** the plan doesn't show who set `eastus` or why, so the cause is a guess until someone finds it. Region policy, live data in the app, and anything else depending on the group are also outside the plan.

**Recommendation:** block this change. If a region move is intended, plan it as a migration: stand up the new region first, cut traffic over, then remove the old one. If it wasn't intended, find where `eastus` was set (a tfvars file, a pipeline variable or the default) and revert it.

## Audit of the first-draft workflow

| Finding | Rule it breaks |
|---|---|
| `ARM_CLIENT_SECRET` in secrets | Use OIDC with `azure/login` and `id-token: write` |
| `terraform apply -auto-approve` | Apply the reviewed `tfplan` file |
| No `environment:` on the apply job | `environment: production` with required reviewers |
| `permissions: write-all` or none set | `contents: read` by default, extras per job |
| No `concurrency` group | One apply at a time, `cancel-in-progress: false` |
| Action pinned to `@main` | Pin to a major version |

**Unverified:** whether `azure/login`, `hashicorp/setup-terraform` and `actions/github-script` are on the organization's approved-actions list.

## Debug of `var.env`

**Root cause:** `locals` in `infra/main.tf` references `var.env`. The declared variable is `var.environment`. It's a typo.

**Smallest fix:** change `var.env` to `var.environment`. Don't add a second variable.

**Proof:** `terraform -chdir=infra validate` now prints `Success! The configuration is valid.`

## Unverified standards (always list these)

Tag naming policy, approved Azure regions, approved Actions list, private networking and firewall rules, and any naming convention beyond what `infra/main.tf` already shows.
