resource "linode_lke_cluster" "main" {
  label       = "topgun-${random_pet.topgun.id}"
  region      = "eu-central"
  k8s_version = var.k8s_version

  pool {
    type  = "g6-standard-1" #Linode 2GB shared CPU
    count = 2
  }
}

resource "random_pet" "topgun" {
  length    = 2
  separator = "-"
}
