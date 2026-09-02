# Deploy Runner for skipprd/skipprd-wal-p

Binds this repository to the Skippr Cloud Runners GitHub App and creates pool
`skipprd-wal-p-linux-x64-1` with labels `self-hosted` and `skippr-linux-x64-1`
(matches `.github/workflows/check.yml`).

Setup follows [Skippr Cloud Deploy Runner](https://skippr.io/cloud/deploy/runner).
Use the published `skippr/cloud` provider from [Terraform and CDKTF](https://skippr.io/cloud/providers).
Sign in and create an access key as in [Cloud User Directory](https://skippr.io/cloud/user-directory#keys-for-terraform-and-ci).

## Apply

Set `CLOUD_ACCESS_KEY_ID` and `CLOUD_SECRET_ACCESS_KEY`. Copy
`terraform.tfvars.example` to `terraform.tfvars` (gitignored) and set
`github_installation_id`. `repo_id` can stay unset; `./apply.sh` fills it from
`gh api`.

```bash
export CLOUD_ACCESS_KEY_ID=...
export CLOUD_SECRET_ACCESS_KEY=...
export CLOUD_REGION=eu-central-1

cd terraform/deploy-runner
cp terraform.tfvars.example terraform.tfvars
# edit github_installation_id

terraform init
terraform plan
terraform apply
```

Or run `./apply.sh` from this directory after the same env vars and tfvars are set.

## Import (if resources already exist)

```bash
terraform import cloud_deploy_runner_repository_binding.wal_p \
  "$(gh api repos/skipprd/skipprd-wal-p --jq .id)"
terraform import cloud_deploy_runner_pool.linux_x64_1 skipprd-wal-p-linux-x64-1
```
