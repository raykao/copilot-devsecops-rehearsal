#!/usr/bin/env bash
# One-time setup for the rehearsal repo: Terraform state storage, an OIDC app
# registration, and the GitHub secrets, variables and environment the workflow reads.
#
#   scripts/bootstrap-azure.sh <github-owner/repo> [--public-state|--local-state]
#
# Needs: az (logged in, Owner or User Access Administrator on the subscription),
# gh (logged in, admin on the repo). Teardown: scripts/bootstrap-azure.sh <repo> --destroy
set -euo pipefail

REPO="${1:?usage: bootstrap-azure.sh <owner/repo> [--public-state|--local-state|--destroy]}"
MODE="${2:-}"
LOCATION="${LOCATION:-canadaeast}"
STATE_RG="rg-dep2-tfstate"
APP_NAME="dep2-devsecops-demo-oidc"
ENVIRONMENT="production"

SUB_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"

if [[ "$MODE" == "--destroy" ]]; then
  az group delete -n "$STATE_RG" --yes --no-wait
  APP_ID="$(az ad app list --display-name "$APP_NAME" --query '[0].appId' -o tsv)"
  [[ -n "$APP_ID" ]] && az ad app delete --id "$APP_ID"
  echo "Deleted $STATE_RG and $APP_NAME. Delete rg-wealth-accounts-* separately."
  exit 0
fi

# Storage name must be globally unique, 3-24 lowercase letters and digits.
STATE_SA="stdep2$(echo -n "$SUB_ID$REPO" | shasum | cut -c1-12)"

LOCAL=false; [[ "$MODE" == "--local-state" ]] && LOCAL=true

if ! $LOCAL; then
echo "==> State storage ($STATE_SA)"
az group create -n "$STATE_RG" -l "$LOCATION" -o none
# Encrypted at rest and in transit. No anonymous access and no shared keys:
# only Entra ID identities with a data role can read or write state.
PUBLIC=Disabled
[[ "$MODE" == "--public-state" ]] && PUBLIC=Enabled
az storage account create -n "$STATE_SA" -g "$STATE_RG" -l "$LOCATION" \
  --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 \
  --https-only true --allow-blob-public-access false --allow-shared-key-access false \
  --public-network-access "$PUBLIC" -o none
SA_ID="$(az storage account show -n "$STATE_SA" -g "$STATE_RG" --query id -o tsv)"
fi

echo "==> App registration and federated credentials"
APP_ID="$(az ad app list --display-name "$APP_NAME" --query '[0].appId' -o tsv)"
if [[ -z "$APP_ID" ]]; then
  APP_ID="$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)"
  az ad sp create --id "$APP_ID" -o none
fi

# The subject format depends on the GitHub account type. Managed users emit
# repo:<user>@<id>/<repo>@<repo-id>:..., so register both forms.
REPO_ID="$(gh api "repos/$REPO" --jq .id)"
OWNER="${REPO%%/*}"; NAME="${REPO##*/}"
for SUBJECT in \
  "repo:$REPO:environment:$ENVIRONMENT" \
  "repo:$REPO:environment:plan" \
  "repo:$OWNER/$NAME@$REPO_ID:environment:$ENVIRONMENT" \
  "repo:$OWNER/$NAME@$REPO_ID:environment:plan" \
  "repo:$(gh api user --jq .login)@$(gh api user --jq .id)/$NAME@$REPO_ID:environment:$ENVIRONMENT" \
  "repo:$(gh api user --jq .login)@$(gh api user --jq .id)/$NAME@$REPO_ID:environment:plan"; do
  CRED_NAME="gh-$(echo -n "$SUBJECT" | shasum | cut -c1-10)"
  az ad app federated-credential create --id "$APP_ID" --parameters "{
    \"name\": \"$CRED_NAME\", \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"$SUBJECT\", \"audiences\": [\"api://AzureADTokenExchange\"]}" -o none 2>/dev/null || true
done
echo "    If azure/login still fails, copy the subject from the error and add it as a credential."

echo "==> Role assignments"
az role assignment create --assignee "$APP_ID" --role Contributor --scope "/subscriptions/$SUB_ID" -o none
if ! $LOCAL; then
  az role assignment create --assignee "$APP_ID" --role "Storage Blob Data Contributor" --scope "$SA_ID" -o none
  # The container is created by the signed-in user, who needs the same data role.
  ME="$(az ad signed-in-user show --query id -o tsv)"
  az role assignment create --assignee "$ME" --role "Storage Blob Data Contributor" --scope "$SA_ID" -o none
  sleep 30
  az storage container create --account-name "$STATE_SA" -n tfstate --auth-mode login -o none
fi

echo "==> GitHub secrets, variables and environment"
gh api -X PUT "repos/$REPO/environments/plan" >/dev/null
gh api -X PUT "repos/$REPO/environments/$ENVIRONMENT" >/dev/null 2>&1 || true
for E in plan "$ENVIRONMENT"; do
  gh secret set AZURE_CLIENT_ID -R "$REPO" --env "$E" -b "$APP_ID"
  gh secret set AZURE_TENANT_ID -R "$REPO" --env "$E" -b "$TENANT_ID"
  gh secret set AZURE_SUBSCRIPTION_ID -R "$REPO" --env "$E" -b "$SUB_ID"
done
if ! $LOCAL; then
  gh variable set TFSTATE_RESOURCE_GROUP -R "$REPO" -b "$STATE_RG"
  gh variable set TFSTATE_STORAGE_ACCOUNT -R "$REPO" -b "$STATE_SA"
fi
ME_GH="$(gh api user --jq .id)"
if ! gh api -X PUT "repos/$REPO/environments/$ENVIRONMENT" \
  --input - <<<"{\"reviewers\":[{\"type\":\"User\",\"id\":$ME_GH}]}" >/dev/null 2>&1; then
  # Required reviewers need a public repo or a paid plan.
  gh api -X PUT "repos/$REPO/environments/$ENVIRONMENT" >/dev/null
  echo "    No required reviewer (plan doesn't support it on a private repo): apply runs without an approval screen."
fi

echo
if $LOCAL; then echo "Done. Local state: change the workflow init steps to -backend=false."; else echo "Done. State: $STATE_SA (public network access: $PUBLIC)."; fi
! $LOCAL && [[ "$PUBLIC" == "Disabled" ]] && echo "GitHub-hosted runners can't reach it. Re-run with --public-state, or use a self-hosted runner."
echo "Reminder: set the location default to $LOCATION before the rehearsal."
