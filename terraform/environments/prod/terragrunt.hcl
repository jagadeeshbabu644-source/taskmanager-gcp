locals {
  # Reads from TF_VAR_project_id env var - NOT hardcoded - safe to commit!
  project_id  = get_env("TF_VAR_project_id", "YOUR_PROJECT_ID")
  region      = "us-central1"
  zone        = "us-central1-a"
  environment = "prod"
}
remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "${local.project_id}-tfstate"
    prefix = "terraform/${local.environment}/${path_relative_to_include()}"
  }
}
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<PEOF
provider "google" {
  project = "${local.project_id}"
  region  = "${local.region}"
}
provider "google-beta" {
  project = "${local.project_id}"
  region  = "${local.region}"
}
PEOF
}
inputs = {
  project_id  = local.project_id
  region      = local.region
  zone        = local.zone
  environment = local.environment
}
