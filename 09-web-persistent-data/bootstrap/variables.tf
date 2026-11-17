# variables.tf
variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "uksouth"
}

variable "prefix" {
  type    = string
  default = "lab"
}

# GitHub repo that is allowed to deploy, as "owner/repo"
variable "github_repo" {
  type = string
}

# GitHub's OIDC token subject can include immutable IDs: "owner@ownerId/repo@repoId".
# Copy it from the failed run's error message. Null = use github_repo.
variable "github_oidc_subject_repo" {
  type    = string
  default = null
}

# Other repos allowed to deploy with the same app, as short name => subject repo.
# Use the "owner@ownerId/repo@repoId" form, like github_oidc_subject_repo.
variable "extra_github_repos" {
  type    = map(string)
  default = {}
}
