variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "Skippr Cloud region (CLOUD_REGION)."
}

variable "github_installation_id" {
  type        = string
  sensitive   = true
  description = "Skippr Cloud Runners GitHub App installation id. Set TF_VAR_github_installation_id or terraform.tfvars; do not commit the value."
}

variable "repo_id" {
  type        = string
  description = "Numeric GitHub repository id. apply.sh fills this from gh api when unset."
}

variable "repo_owner" {
  type    = string
  default = "skipprd"
}

variable "repo_name" {
  type    = string
  default = "skipprd-wal-p"
}

variable "default_branch" {
  type    = string
  default = "main"
}

variable "pool_id" {
  type    = string
  default = "skipprd-wal-p-linux-x64-1"
}

variable "pool_size" {
  type    = string
  default = "linux_x64_1"
}

variable "pool_labels" {
  type = list(string)
  default = [
    "self-hosted",
    "linux",
    "x64",
    "skippr-linux-x64-1",
  ]
}

variable "pool_image" {
  type    = string
  default = "skippr-ubuntu-24.04-x64"
}

variable "pool_max_concurrent" {
  type    = number
  default = 2
}

variable "pool_fork_policy" {
  type        = string
  default     = "deny"
  description = "GitHub fork run policy for this pool."
}
