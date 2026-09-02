#!/usr/bin/env bash
# Apply skipprd-wal-p Deploy Runner bind with the published skippr/cloud provider.
# Credentials: https://skippr.io/cloud/user-directory#keys-for-terraform-and-ci
# Resources: https://skippr.io/cloud/deploy/runner
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if [[ -z "${CLOUD_ACCESS_KEY_ID:-}${CLOUD_OPERATOR_ACCESS_KEY_ID:-}" ]]; then
  echo "Set CLOUD_ACCESS_KEY_ID and CLOUD_SECRET_ACCESS_KEY (see https://skippr.io/cloud/user-directory#keys-for-terraform-and-ci)." >&2
  exit 1
fi

export CLOUD_REGION="${CLOUD_REGION:-eu-central-1}"

if [[ -z "${TF_VAR_repo_id:-}" ]] && ! grep -Eq '^[[:space:]]*repo_id[[:space:]]*=' terraform.tfvars 2>/dev/null; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "Set TF_VAR_repo_id or install gh to resolve the GitHub repository id." >&2
    exit 1
  fi
  export TF_VAR_repo_id
  TF_VAR_repo_id="$(gh api "repos/${TF_VAR_repo_owner:-skipprd}/${TF_VAR_repo_name:-skipprd-wal-p}" --jq .id)"
fi

if [[ -z "${TF_VAR_github_installation_id:-}" ]] && ! grep -Eq '^[[:space:]]*github_installation_id[[:space:]]*=' terraform.tfvars 2>/dev/null; then
  echo "Set github_installation_id in terraform.tfvars or TF_VAR_github_installation_id." >&2
  exit 1
fi

terraform init -input=false
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
