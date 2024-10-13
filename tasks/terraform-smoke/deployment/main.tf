locals {
  name = "bin-smoke-${random_pet.smoke.id}"
}

resource "hcloud_network" "main" {
  name     = local.name
  ip_range = "10.6.0.0/16"
}

resource "hcloud_network_subnet" "public" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.6.1.0/24"
}

resource "hcloud_server" "main" {
  name         = local.name
  server_type  = "ccx13"
  image        = var.image
  ssh_keys     = ["ci-tests"]
  location     = "fsn1"
  firewall_ids = [hcloud_firewall.main.id]

  network {
    network_id = hcloud_network.main.id
    alias_ips  = []
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}

resource "null_resource" "rerun" {
  depends_on = [hcloud_server.main]

  triggers = {
    rerun = uuid()
  }

  connection {
    type        = "ssh"
    host        = hcloud_server.main.ipv4_address
    user        = "root"
    private_key = file("${path.module}/keys/private_key")
  }

  # Provisioners are executed in the order they are declared
  provisioner "remote-exec" {
    script = "${path.module}/setup-postgresql.sh"
  }

  provisioner "file" {
    destination = "/tmp/concourse.tgz"
    source      = var.concourse_tarball
  }

  provisioner "remote-exec" {
    script = "${path.module}/setup-concourse.sh"
  }

  provisioner "file" {
    destination = "/usr/local/concourse/system/concourse-web.service"
    source      = "${path.module}/systemd/concourse-web.service"
  }

  provisioner "file" {
    destination = "/usr/local/concourse/system/concourse-worker.service"
    source      = "${path.module}/systemd/concourse-worker.service"
  }

  provisioner "file" {
    destination = "/etc/systemd/system/concourse-web.service.d/smoke.conf"
    content = templatefile("${path.module}/systemd/smoke-web.conf.tpl",
      {
        instance_ip    = hcloud_server.main.ipv4_address
        admin_password = random_string.admin_password.result
        guest_password = random_string.guest_password.result
      }
    )
  }

  provisioner "file" {
    destination = "/etc/systemd/system/concourse-worker.service.d/smoke.conf"
    content = templatefile("${path.module}/systemd/smoke-worker.conf.tpl",
      {
        runtime = var.runtime
      }
    )
  }

  provisioner "remote-exec" {
    script = "${path.module}/start-concourse.sh"
  }
}
resource "hcloud_firewall" "main" {
  name = local.name

  rule {
    description = "SSH access"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    description = "Web access"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "random_pet" "smoke" {
  length    = 2
  separator = "-"
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
