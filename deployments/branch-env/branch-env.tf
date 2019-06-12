variable "project" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

provider "google" {
  credentials = "keys/gcp.json"
  project     = var.project
  region      = var.region
}

resource "google_compute_target_pool" "web" {
  name = "${terraform.workspace}-web-target-pool"
  health_checks = ["${google_compute_http_health_check.web.name}"]
}

resource "google_compute_forwarding_rule" "web" {
  name = "${terraform.workspace}-web-forwarding-rule"
  target = "${google_compute_target_pool.web.self_link}"
  port_range = "1-65535"
}

resource "google_compute_http_health_check" "web" {
  name = "${terraform.workspace}-web-health-check"
  port = 80
  request_path = "/api/v1/info"
  healthy_threshold = 1
  unhealthy_threshold = 10
}

resource "google_dns_record_set" "concourse-ci-org-dns" {
  name = "${terraform.workspace}.concourse-ci.org."
  type = "A"
  ttl  = 300

  managed_zone = "concourse-ci-org"

  rrdatas = ["${google_compute_forwarding_rule.web.ip_address}"]
}
