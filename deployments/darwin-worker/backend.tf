terraform {
  backend "gcs" {
    bucket = "concourse-greenpeace"
    prefix = "darwin-worker"
  }
}
