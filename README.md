# Copilot for DevOps: AI-SDLC IaC and pipelines demo

A standalone 60-minute, instructor-led session. Copilot scaffolds Azure infrastructure and a CI/CD pipeline for a fake banking service, reviews a risky Terraform plan, audits its own pipeline, and a human approves and applies. No real code or customer data.

## Prerequisites

- VS Code with GitHub Copilot Chat
- Terraform 1.7 or later
- Node 20 (only for the sample API and helper script)

No Azure subscription is needed. The demo never runs `terraform apply`.

## Get ready

1. Open the repo in VS Code (or the dev container).
2. Run the **Infra: init (no backend)** task once.
3. Run the **Demo: preflight** task. Every line should say PASS.
4. Follow [docs/RUN-OF-SHOW.md](docs/RUN-OF-SHOW.md).

## Layout

| Path | Purpose |
|---|---|
| `app/server.js` | Sample accounts API with a `/api/health` endpoint |
| `infra/main.tf` | Starter Terraform: provider, variables, tags, resource group |
| `infra/samples/` | Hand-written plan and a CI failure log |
| `.github/workflows/infra.yml` | Starter pipeline stub |
| `.github/instructions/`, `prompts/`, `agents/` | Rules, `/scaffold-infra`, `/scaffold-pipeline`, `/explain-plan` and the `devops` agent |
| `specs/INFRA.md` | The brief Copilot builds from |
| `solutions/infra/` | Answer key (hidden from Copilot search) |
| `docs/` | Run of show, saved answers, slide deck and PDF |

## Helper commands

`node scripts/demo.mjs <preflight|solution|reset|break|restore>`, also available as VS Code tasks. `reset` uses `git checkout`, so commit nothing from a rehearsal.

## Known gaps

Not run against live Azure or GitHub Actions. The sample plan is hand-written. See the end of the run of show.
