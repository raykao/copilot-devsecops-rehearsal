# Copilot instructions

This repo is a sample banking service (Wealth Accounts API) used to teach infrastructure-as-code and pipeline-as-code with GitHub Copilot. All data is fake.

- `app/` is a small Node 20 API. `infra/` is Terraform for Azure. `.github/workflows/infra.yml` is the pipeline.
- Path-specific rules live in `.github/instructions/`. Follow them.
- Generated code is a draft. A human reviews and is accountable for it.
- Check generated work for secrets, personal data in logs, over-broad permissions, unpinned actions and unapproved dependencies.
- If a standard (tag policy, approved regions, approved actions list) is not in this repo, say it is unverified. Do not invent it.
- Never run `terraform apply` or `terraform destroy`, and never suggest `-auto-approve`.
