---
name: scaffold-pipeline
description: Build the infra pipeline (validate, plan on PR, gated apply on main) with OIDC and approval guardrails
agent: agent
argument-hint: "workflow=.github/workflows/infra.yml"
---

Extend `${input:workflow:.github/workflows/infra.yml}` into the pipeline for `infra/`.

Read [workflow instructions](../instructions/workflows.instructions.md) first. Then build:

Trigger on pull requests and pushes to `main` that touch `infra/**`, `app/**` or this workflow file.

1. **validate** (every run): `terraform fmt -check`, `terraform init -backend=false`, `terraform validate`.
2. **plan** (pull requests, after validate): run in the `plan` environment (it holds the Azure secrets and needs no approval), log in to Azure with OIDC, run `terraform init`, run `terraform plan -out=tfplan`, and post the plan as a pull request comment even when the plan fails.
3. **apply** (push to `main` only, after validate): behind the `production` environment, re-run `terraform plan -out=tfplan` in the apply job (a PR plan file isn't available on `main`), then apply that file. After the apply, deploy the app: zip the `app/` directory itself (`zip -r app.zip app`, so `node app/server.js` resolves) and push it with `az webapp deploy --type zip`, using the `api_app_name` and `resource_group_name` outputs.
4. **smoke** (after apply): `curl --fail` the `/api/health` endpoint of the `api_hostname` output, retrying for up to two minutes.
5. **rollback**: a `workflow_dispatch` input `rollback_ref` that checks out that commit and re-applies it behind the same `production` environment.

State is local to each run (no remote backend), so use plain `terraform init` in the plan and apply jobs. Azure IDs come from the environment secrets `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` and `AZURE_SUBSCRIPTION_ID`.

When you're done, check your own work against the instructions file and list any guardrail you couldn't meet. Don't run anything that touches Azure.
