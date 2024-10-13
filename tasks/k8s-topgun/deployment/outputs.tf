output "kube_config" {
  value     = linode_lke_cluster.main.kubeconfig
  sensitive = true
}
