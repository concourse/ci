backend "gcs" {
  credentials = "keys/gcp.json"
  prefix      = "terraform/state"
}
