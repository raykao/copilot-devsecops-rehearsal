# Run of show: AI-SDLC for DevOps (IaC and pipelines), 60 minutes

Audience: DevOps and release-management engineers. Level: intermediate (L200). Surface: VS Code with Copilot Chat; GitHub.com for the PR. The CLI is a one-line look-ahead only. Sample app: a fake banking accounts API. No real BMO code or data.

**The editing steps run offline; the Azure steps are shown from a pre-built run.** Before you start, run the **Demo: preflight** task. If it fails, it tells you which task to run. See "Pre-demo: pre-create the Azure runs" below, so nobody watches a deploy.

- Slides: `docs/deck/` (`npm run dev` there) or `docs/deck.pdf`
- Saved answers for when Copilot is slow: `docs/SAVED-ANSWERS.md`
- Fallback for any step: **Demo: jump to the answer key**, then open the file and narrate it. Undo with **Demo: reset to starter**.

## Timeline

| Clock | Block | Slides | Cut order |
|---|---|---|---|
| 0:00 | Frame: stakes and guardrails | 1–3 | Keep |
| 0:05 | Scaffold the infrastructure | 4–5 | Keep |
| 0:15 | Review a plan like an approver | 6–7 | **Keep, best moment** |
| 0:23 | Scaffold the pipeline and audit it | 8–9 | Keep |
| 0:35 | Smoke check and rollback | 10 | Cut second |
| 0:43 | Break and fix | 11 | Cut first |
| 0:51 | Review checklist and what Copilot can't verify | 12 | Keep |
| 0:56 | Questions and wrap | 13–14 | Keep |

**Short path (45 min):** drop break and fix, and shorten smoke and rollback to walking the finished workflow. Keep the plan review and the audit.

**Filling Copilot's wait time:** agent runs take 30 to 90 seconds. Narrate: "Watch what it reads first. It's looking for the existing resource group so it can copy the naming."

## Pre-demo: pre-create the Azure runs

Timings are from a live test run on 20 Oct. Never wait on these in front of the room.

| Step | Observed | Live or pre-built |
|---|---|---|
| validate job | ~10 s | Live, short enough to watch |
| plan job (init, OIDC login, plan) | 25–40 s | **Pre-built**: an open PR with the plan comment already posted |
| apply job (Azure creates plan and web app) | **1m50s to 4m15s** | **Pre-built**: a green run to walk through |
| smoke check, passing | 15–30 s after deploy | Pre-built, part of the same run |
| smoke check, failing | **~4 min** (12 retries at 10 s) | **Never live**: show a saved red run |
| rollback | ~35 s to apply, then apply time | **Pre-built**: the run plus the approval screen |
| production approval click | instant | Live, if a reviewer is set |
| Copilot agent runs | 30–90 s | Live, narrate while it works |
| explain-plan, audit, break and fix | 10–40 s | Live |
| terraform fmt and validate | under 5 s | Live |

**This repo is the live demo repo.** The Azure side is already configured, so nothing is set up on stage:

| Already in place | Where |
|---|---|
| Entra app registration `dep2-devsecops-demo-oidc`, `Contributor` on the subscription | Azure |
| Federated credentials for `environment:production` and `environment:plan` (three subject formats each) | Azure |
| `production` environment, you as required reviewer | GitHub |
| `plan` environment, no reviewer | GitHub |
| `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` as **environment** secrets in both environments (no repo-level secrets) | GitHub |

The pipeline Copilot writes must put the plan job in `environment: plan` and the apply and rollback jobs in `environment: production`. The scaffold-pipeline prompt says so. If the generated plan job has no environment, it can't see the secrets and `azure/login` fails.

**State is local.** This subscription's policy forces storage public access off, so GitHub-hosted runners can't reach a remote backend. `infra/main.tf` has no backend block and the pipeline uses plain `terraform init`. Say so on slide 10 if asked. The proper answer is a self-hosted runner with a private endpoint, which Copilot can't verify.

**Live path, end to end**
1. Run the prompts in order (scaffold-infra, explain-plan, scaffold-pipeline). The files stay local until you commit.
2. Commit the result on a branch and open a PR. The plan job runs in about 40 s and posts the comment. This needs no approval.
3. Merge the PR in the GitHub UI. A merge is a push to `main`, so the apply job starts and **waits for your approval**. Approve it, then keep talking: apply takes 2 to 4 minutes and the smoke check follows.
4. Don't wait on it. Switch to the pre-built runs below while it finishes.

**Pre-built runs (captured 21 Oct, same repo, history kept)**

| Cue | Link |
|---|---|
| PR with the plan comment | <https://github.com/raykao/copilot-devsecops-rehearsal/pull/1> |
| Green apply and smoke | <https://github.com/raykao/copilot-devsecops-rehearsal/actions/runs/39606784785> |
| Red smoke (deploy step removed) | <https://github.com/raykao/copilot-devsecops-rehearsal/actions/runs/39608377086> |
| Rollback to the green commit | <https://github.com/raykao/copilot-devsecops-rehearsal/actions/runs/39609556035> |
| Rollback waiting for approval (live approve cue) | <https://github.com/raykao/copilot-devsecops-rehearsal/actions/runs/39612186756> |

The repo is **public** so the `production` environment can require your approval. A scan found no credentials: no GUIDs in any commit, and run logs mask the tenant, subscription and client IDs. Make it private again after the session (`gh repo edit raykao/copilot-devsecops-rehearsal --visibility private`).

**Local-state caveats**
- Every run starts with empty state. A second apply or a rollback fails with "resource group already exists" unless you delete `rg-wealth-accounts-dev` first. Delete it before the demo and between any repeated runs.
- The waiting rollback run is stale. Don't approve it unless `rg-wealth-accounts-dev` is deleted; it just re-applies the old green commit.
- If `azure/login` fails with an OIDC subject you haven't registered, copy the subject from the error and add it as a federated credential on the app.

**Day-before checklist**
1. Run `terraform -chdir=infra init -backend=false`, then **Demo: preflight**. All 9 checks should pass.
2. Delete `rg-wealth-accounts-dev` so the live apply starts clean.
3. Confirm the environments: `gh api repos/raykao/copilot-devsecops-rehearsal/environments --jq '.environments[].name'` shows `plan` and `production`, and each has three secrets.
4. Do one dry run of the live path (steps 1 to 3 above) if time allows, then delete the resource group again.
5. Open these tabs in order: PR with plan comment, green apply run, green smoke job, red smoke run, rollback approval, rollback run.
6. Tear down afterward: delete `rg-wealth-accounts-*`, make the repo private, and optionally run `scripts/bootstrap-azure.sh <owner>/<repo> --destroy` to remove the app registration.

**Cue on each affected slide**
- Slide 8 (pipeline): after the scaffold, say "this ran earlier" and open the PR plan comment and the green apply run.
- Slide 10 (smoke and rollback): open the green smoke job, then the red run, then the rollback approval. Don't trigger anything.
- Slide 11 (break and fix): only the local `terraform validate` runs live. The CI log is `infra/samples/failed-validate.log`.

## 0:00 Frame (5 min, slides 1 to 3)

**Say:** "In app code a bad suggestion fails a test. In infrastructure it can delete a live resource group. So Copilot drafts and explains, and a human approves and applies."

Slide 2 sets the contract for the hour: generated code is a draft, a human is accountable. Slide 12 returns to it with the checklist: secrets, authorization, personal data in logs, error handling and dependencies.

**Ask the room:** "Who has a pipeline they're afraid to touch?" Use the answers later.

## 0:05 Scaffold the infrastructure (10 min, slides 4 and 5)

```text
/scaffold-infra spec=specs/INFRA.md
```

**Expect:** a plan that cites `rg-${local.name_prefix}` and `local.tags`, then a service plan and Linux web app appended to `infra/main.tf`, a `transfer_limit` variable, `api_hostname`, `api_app_name` and `resource_group_name` outputs and a clean `terraform validate`. Approve the plan it shows first.

**Say:** "It's finding the closest existing thing and copying its shape. Here that's the resource group."

**Watch for:** a second `tags` block, a hard-coded region, or an old Node version. Ask "does this follow our conventions?" Compare with `solutions/infra/main.tf`.

**Checkpoint:** by 0:12 the scaffold is approved and validating. If not, jump to the answer key.

**Landing line:** "Notice the last thing it said: which parts of the spec it couldn't verify. That's the habit we want."

## 0:15 Review a plan (8 min, slides 6 and 7)

Show slide 6 and give the room 20 seconds to read the sample plan. Ask "Is this safe to apply?" Most say yes. Let them be wrong.

```text
/explain-plan plan=infra/samples/plan-forced-replacement.txt
```

**Answer key:** 3 to add, 3 to destroy. `location = "canadacentral" -> "eastus" # forces replacement` on the resource group; the plan and web app are replaced because they depend on it. It should also list what it can't verify (who set `eastus`, region policy). Recommendation: block. A region move is a migration, not an edit.

The plan is hand-written in real `terraform plan` format, so no Azure subscription is needed. Say so if asked.

**Landing line:** "The scariest part was one changed default, easy to miss in a pull request."

## 0:23 Scaffold the pipeline and audit it (12 min, slides 8 and 9)

```text
/scaffold-pipeline workflow=.github/workflows/infra.yml
```

**Expect:** `validate`, `plan`, `apply` (re-plans, applies, then zip-deploys `app/`), smoke and rollback. OIDC login, plan posted as a PR comment, `environment: production` on apply.

Then paste: *"Audit this workflow against the workflow instructions. What violates them? List anything you can't verify, such as whether these actions are on an approved list."*

**The audit may come back clean.** The prompt and instructions already forbid the usual misses, so say so and move on. Then ask what it *couldn't* verify: it should name `azure/login`, `setup-terraform` and `github-script` as actions it can't check against an approved list.

**If it does slip, the usual first-draft misses are:** a stored `ARM_CLIENT_SECRET`, `-auto-approve`, no `concurrency`, `permissions: write-all`, an action pinned to `@main`. Make Copilot find them; don't fix them for it.

**Ask the room:** "Which of these would your current review process catch?"

## 0:35 Smoke check and rollback (8 min, slide 10)

Walk the finished `smoke` and `rollback` jobs in `solutions/infra/.github/workflows/infra.yml`.

- **Deploy:** the apply job zips `app/` and pushes it, so there is something to health-check.
- **Smoke:** after apply, `curl --fail` the `/api/health` of the deployed hostname, retrying for two minutes. Failure prints the rollback instruction.
- **Rollback:** run the workflow manually with `rollback_ref` set to a known-good commit. It re-applies that commit behind the same `production` approval.

**Say:** "Rollback is not a special button. It's the same reviewed path, pointed at an older commit."

## 0:43 Break and fix (8 min, slide 11)

1. Run **Demo: break the pipeline**.
2. In a regular terminal: `terraform -chdir=infra validate` gives `Reference to undeclared input variable ... var.env`.
3. Switch to the **devops** agent: `#terminalLastCommand This is the step that failed in CI. What's the root cause and the smallest fix?`

**Note:** the error's line number depends on how much the scaffold added (50 in the starter, about 56 after it). Don't read it out; point at the variable name.

**Expect:** a typo (`var.env` for `var.environment`) fixed in `locals`. A weaker fix adds a new `env` variable; ask why that creates two sources of truth.

**Skip:** **Demo: restore**. `infra/samples/failed-validate.log` has the same failure as a CI log.

## 0:51 Review checklist and what Copilot can't verify (5 min, slide 12)

Walk the checklist: secrets, authorization and permissions, personal data in logs, error handling, dependencies and actions. Then the "unverified" list: tag policy, approved regions, approved actions, private networking. Those live in your org, not this repo.

## 0:56 Questions and wrap (4 min, slides 13 and 14)

**Look-ahead (one sentence):** the Copilot CLI can run the same prompts and agents from a terminal. Not covered today.

| Question | Short answer |
|---|---|
| "Does the plan job really run `terraform plan` against production?" | Yes, read-only, with OIDC, posted on the PR. On merge, the apply job re-plans on main, pauses at the `production` approval, then applies that saved `tfplan`. |
| "Where does state live?" | In an Azure Storage backend configured by repo variables. Not in git. |
| "Why not let Copilot apply?" | Apply is irreversible. The gate is the `production` environment, not a prompt. |
| "Can Copilot see our real plan?" | Only if you paste it or it's posted as a PR comment. Redact secrets first. |
| "Does this work with Bicep?" | Yes. Swap the instructions file. The workflow stays the same. |
| "Is the sample plan real?" | Hand-written in real format so the demo needs no subscription. |
| "Does this run on our private network?" | Out of scope here. List it as an unverified standard and confirm with your platform team. |

## Known gaps

Nothing here has been run against a live Azure subscription or GitHub Actions, and the prompts have not been run end to end in a customer environment. `actionlint` was not run. Do a rehearsal.
