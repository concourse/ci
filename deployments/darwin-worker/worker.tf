variable "macstadium_ip" {
  type = string
}

variable "macstadium_username" {
  type = string
}

variable "macstadium_password" {
  type = string
}

variable "concourse_bundle_url" {
  type    = string
  default = "https://github.com/concourse/concourse/releases/download/v7.0.0/concourse-7.0.0-darwin-amd64.tgz"
}

variable "go_version" {
  type    = string
  default = "1.16"
}

resource "null_resource" "instance" {
  triggers = {
    ip         = var.macstadium_ip
    url        = var.concourse_bundle_url
    go_version = var.go_version
  }

  connection {
    type     = "ssh"
    host     = var.macstadium_ip
    user     = var.macstadium_username
    password = var.macstadium_password
  }

  provisioner "file" {
    source      = "${path.module}/keys"
    destination = "/Users/administrator/keys"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/concourse.sh"
    destination = "/Users/administrator/concourse.sh"
  }

  provisioner "remote-exec" {
    inline = [
      templatefile("${path.module}/scripts/startup.sh.tmpl", {
        password             = var.macstadium_password,
        concourse_bundle_url = var.concourse_bundle_url,
        go_version           = var.go_version,
      })
    ]
  }
}
