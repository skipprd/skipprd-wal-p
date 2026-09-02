# skipprd/skipprd-wal-p Deploy Runner bind.
# See https://skippr.io/cloud/deploy/runner

resource "cloud_deploy_runner_repository_binding" "wal_p" {
  repo_id         = var.repo_id
  installation_id = var.github_installation_id
  owner           = var.repo_owner
  name            = var.repo_name
  default_branch  = var.default_branch
}

resource "cloud_deploy_runner_pool" "linux_x64_1" {
  pool_id         = var.pool_id
  installation_id = var.github_installation_id
  repository_id   = cloud_deploy_runner_repository_binding.wal_p.repo_id
  size            = var.pool_size
  labels          = var.pool_labels
  image           = var.pool_image
  max_concurrent  = var.pool_max_concurrent
  fork_policy     = var.pool_fork_policy
}
