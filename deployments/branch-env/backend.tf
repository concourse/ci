terraform {
  backend "gcs" {
    credentials = "keys/gcp.json"
    bucket      = "concourse-branch-env-state"
    prefix      = "terraform/state"
  }
}
