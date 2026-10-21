---
name: scaffold-infra
description: Add Azure infrastructure to infra/ from a brief, matching the existing Terraform conventions
agent: agent
argument-hint: "spec=specs/INFRA.md"
---

Add the infrastructure described in `${input:spec:specs/INFRA.md}` to `infra/main.tf`.

Before you write any code:
1. Read the spec, [infra/main.tf](../../infra/main.tf) and [terraform instructions](../instructions/terraform.instructions.md).
2. List the conventions you'll follow, citing where they appear in `main.tf`: naming, tags, location and resource group, variables.
3. Show me a short plan (resources and variables to add, one line each) and wait for my OK.

When I approve the plan:
- Edit `infra/main.tf` only.
- Run `terraform -chdir=infra fmt` and `terraform -chdir=infra validate`. Fix anything they report.
- Summarize what you added and name anything in the spec you couldn't satisfy or verify.

Never run `terraform apply` or `terraform destroy`. Don't add anything the spec lists as out of scope.
