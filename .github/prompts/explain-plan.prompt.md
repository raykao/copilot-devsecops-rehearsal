---
name: explain-plan
description: Read a terraform plan like a reviewer: call out every destroy and forced replacement before anyone applies
agent: ask
argument-hint: "plan=infra/samples/plan-forced-replacement.txt"
---

Review the Terraform plan in `${input:plan:infra/samples/plan-forced-replacement.txt}` as if you were the approver.

1. **Summary:** how many resources are added, changed in place, and destroyed.
2. **Destructive changes:** list every resource that is destroyed or replaced. For each, name the attribute that forces the replacement and say what would be lost (data, hostname, downtime).
3. **Root cause:** trace the forced replacements to the input or change shown in the plan (for example a `location` change). Check [infra/main.tf](../../infra/main.tf) and say whether it confirms the cause. If it doesn't, say the cause is unverified instead of guessing.
4. **Unverified:** list what the plan can't tell you (live data, region policy, dependent services).
5. **Recommendation:** approve, or block with the smallest change that avoids the destruction.

Don't suggest running `terraform apply`. Apply is a human decision.
