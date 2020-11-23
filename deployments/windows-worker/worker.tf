variable "project" {
  type = string
  default = "cf-concourse-production"
}

variable "concourse_tarball" {
  type    = string
  default = "concourse.tgz"
}

variable "region" {
  type    = string
  default = "us-central1"
}

provider "google" {
  project = var.project
  region  = var.region
}

data "google_compute_zones" "available" {
}

resource "google_compute_address" "windows_worker" {
  name = "windows-worker"
}

resource "google_compute_firewall" "windows_worker" {
  name    = "windows-worker-allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  target_tags = ["windows-worker"]
}

resource "google_compute_instance" "windows_worker" {
  name         = "windows-worker"
  machine_type = "custom-8-8192"
  zone         = data.google_compute_zones.available.names[0]
  tags         = ["windows-worker"]

  boot_disk {
    initialize_params {
      image = "windows-server-2004-dc-core-v20201110"
      size  = "32"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.windows_worker.address
    }
  }

  metadata = {
    windows-startup-script-ps1 = data.template_file.startup_script.rendered
  }
}

data "template_file" "startup_script" {
  template = file("scripts/startup.ps1.tmpl")

  vars = {
    tsa_host_public_key = file("keys/tsa_host_key.pub")
    worker_key = file("keys/worker_key")
  }
}
