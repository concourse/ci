variable "image" {
  type        = string
  description = "Hetzner image name (e.g. ubuntu-24.04)"
}

variable "concourse_tarball" {
  type    = string
  default = "concourse.tgz"
}

variable "runtime" {
  type        = string
  description = "Concourse container runtime to test"
}
