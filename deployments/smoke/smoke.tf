variable "project" {
  type = string
}

variable "concourse_tarball" {
  type    = string
  default = "concourse.tgz"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "GCP_IMAGE" {
  type = string
}

variable "RUNTIME" {
  type = string
}

provider "google" {
  credentials = "keys/gcp.json"
  project     = var.project
  region      = var.region
}

data "google_compute_zones" "available" {
}

resource "random_pet" "smoke" {
}

resource "google_compute_address" "smoke" {
  name = "smoke-${random_pet.smoke.id}-ip"
}

resource "google_compute_firewall" "smoke" {
  name    = "smoke-${random_pet.smoke.id}-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags = ["smoke"]
  source_tags = ["smoke"]
}

resource "google_compute_instance" "smoke" {
  name         = "smoke-${random_pet.smoke.id}"
  machine_type = "e2-highcpu-8"
  zone         = data.google_compute_zones.available.names[0]
  tags         = ["smoke"]

  boot_disk {
    initialize_params {
      image = var.GCP_IMAGE
      size  = "30"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.smoke.address
    }
  }

  metadata = {
    sshKeys = "root:${file("keys/id_rsa.pub")}"
  }

  connection {
    type        = "ssh"
    host        = google_compute_address.smoke.address
    user        = "root"
    private_key = file("keys/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "set -e -x",
      "[ -e /var/lib/cloud ] && until [ -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
      # On Debian, apt-get update will fail in the event of a new major release, but --allow-releaseinfo-change prevents that
      length(regexall(".*debian.*", var.GCP_IMAGE)) > 0 ? "apt-get --allow-releaseinfo-change update" : "apt-get update",
      "apt-get -y install postgresql",
      "sudo -i -u postgres createuser concourse",
      "sudo -i -u postgres createdb --owner=concourse concourse",
      "adduser --system --group concourse",
      "mkdir -p /etc/concourse",
      "chgrp concourse /etc/concourse",
    ]
  }
}

resource "random_string" "admin_password" {
  keepers = {
    regen = uuid()
  }

  length  = 16
  special = false
}

resource "random_string" "guest_password" {
  keepers = {
    regen = uuid()
  }

  length  = 16
  special = false
}

data "template_file" "web_conf" {
  template = file("systemd/smoke-web.conf.tpl")

  vars = {
    instance_ip    = google_compute_address.smoke.address
    admin_password = random_string.admin_password.result
    guest_password = random_string.guest_password.result
  }
}

data "template_file" "worker_conf" {
  template = file("systemd/smoke-worker.conf.tpl")

  vars = {
    runtime = var.RUNTIME
  }
}

resource "null_resource" "rerun" {
  depends_on = [google_compute_instance.smoke]

  triggers = {
    rerun = uuid()
  }

  connection {
    type        = "ssh"
    host        = google_compute_address.smoke.address
    user        = "root"
    private_key = file("keys/id_rsa")
  }

  provisioner "file" {
    destination = "/tmp/concourse.tgz"
    source      = var.concourse_tarball
  }

  provisioner "remote-exec" {
    inline = [
      "set -e -x",
      "tar -zxf /tmp/concourse.tgz -C /usr/local",
      "mkdir -p /usr/local/concourse/system",
      "mkdir -p /etc/systemd/system/concourse-web.service.d",
      "mkdir -p /etc/systemd/system/concourse-worker.service.d",
    ]
  }

  # TODO: move .service files into tarball and make them official?
  provisioner "file" {
    destination = "/usr/local/concourse/system/concourse-web.service"
    source      = "systemd/concourse-web.service"
  }

  provisioner "file" {
    destination = "/usr/local/concourse/system/concourse-worker.service"
    source      = "systemd/concourse-worker.service"
  }

  provisioner "file" {
    destination = "/etc/systemd/system/concourse-web.service.d/smoke.conf"
    content     = data.template_file.web_conf.rendered
  }

  provisioner "file" {
    destination = "/etc/systemd/system/concourse-worker.service.d/smoke.conf"
    content     = data.template_file.worker_conf.rendered
  }

  provisioner "file" {
    destination = "/etc/concourse/garden.ini"
    source      = "garden/garden.ini"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e -x",
      "export PATH=/usr/local/concourse/bin:$PATH",
      "concourse generate-key -t rsa -f /etc/concourse/session_signing_key",
      "concourse generate-key -t ssh -f /etc/concourse/host_key",
      "concourse generate-key -t ssh -f /etc/concourse/worker_key",
      "cp /etc/concourse/worker_key.pub /etc/concourse/authorized_worker_keys",
      "chgrp concourse /etc/concourse/*",
      "chmod g+r /etc/concourse/*",
      "systemctl enable /usr/local/concourse/system/concourse-web.service",
      "systemctl restart concourse-web.service",
      "systemctl enable /usr/local/concourse/system/concourse-worker.service",
      "systemctl restart concourse-worker.service",
    ]
  }
}

output "instance_url" {
  value = "https://${google_compute_address.smoke.address}.nip.io"
}

output "admin_password" {
  value     = random_string.admin_password.result
  sensitive = true
}

output "guest_password" {
  value     = random_string.guest_password.result
  sensitive = true
}
