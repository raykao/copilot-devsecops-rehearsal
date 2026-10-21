---
applyTo: ".github/workflows/**"
---

# GitHub Actions conventions

- Set top-level `permissions: contents: read` and add job-level permissions only where needed (`id-token: write` for Azure OIDC, `pull-requests: write` to comment).
- Authenticate to Azure with OIDC (`azure/login@v2` plus `client-id`, `tenant-id`, `subscription-id`). Never store a client secret, and never add `creds:` or `ARM_CLIENT_SECRET`.
- Reference IDs through `secrets.*` and shared settings through `vars.*`. Never inline them.
- Pull requests run format, validate and plan. Only pushes to `main` can apply, and the apply job must use `environment: production` so required reviewers gate it.
- Apply the plan that was reviewed (`terraform apply tfplan`), never `-auto-approve` against fresh changes.
- After an apply, run a smoke check against the deployed health endpoint. A rollback is a manual run that re-applies a known-good commit behind the same `production` approval.
- Only use actions from the organization's approved list. If you cannot verify an action is approved, say so.
- Pin actions to a major version (`@v4`). Use `concurrency` so two applies can't run at once.
