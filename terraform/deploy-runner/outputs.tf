output "repository_binding_id" {
  value = cloud_deploy_runner_repository_binding.wal_p.id
}

output "pool_id" {
  value = cloud_deploy_runner_pool.linux_x64_1.pool_id
}

output "pool_labels" {
  value = cloud_deploy_runner_pool.linux_x64_1.labels
}
