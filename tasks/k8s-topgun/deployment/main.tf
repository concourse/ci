resource "linode_lke_cluster" "main" {
  label       = "topgun-${random_pet.topgun.id}"
  region      = "eu-central"
  k8s_version = var.k8s_version

  pool {
    type  = "g6-standard-6" #Linode 16GB shared CPU
    count = 4
  }
}

resource "random_pet" "topgun" {
  length    = 2
  separator = "-"
}
