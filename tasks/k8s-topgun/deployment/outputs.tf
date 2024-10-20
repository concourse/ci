output "kube_config" {
  value     = linode_lke_cluster.main.kubeconfig
  sensitive = true
}

output "node_pool_size" {
  value = local.node_pool_size
}
