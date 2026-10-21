---
applyTo: "infra/**"
---

# Terraform conventions

- One `main.tf` for now. Providers are pinned with `~>`; keep `required_version` and the lock file (`.terraform.lock.hcl`) committed.
- Name resources `<type-prefix>-${local.name_prefix}` (`rg-`, `plan-`, `app-`). Never hard-code names, regions or environments; use variables.
- Apply tags through `local.tags` only. Don't write a second tags block.
- Take `location` and `resource_group_name` from the resource group resource, not from variables, so everything moves together.
- Every variable has a `description` and a `type`. Every output has a `description`.
- Security defaults: `https_only = true`, `minimum_tls_version = "1.2"`, `ftps_state = "Disabled"`. No secrets in `.tf` files or variable defaults.
- Format with `terraform fmt`. Check with `terraform validate`.
- **Never run `terraform apply` or `terraform destroy`.** Run `terraform plan` only if the user asks, and explain destroys and replacements before anyone applies.
- Generated code is a draft and a human is accountable for it. List any standard you could not verify from this repo (tag policy, approved regions, private networking) instead of guessing.
