terraform {
  backend "gcs" {
    bucket      = "concourse-greenpeace"
    prefix      = "deleteme-vito-windows-worker"
  }
}
