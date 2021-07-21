output "kubeconfig" {
  sensitive = true
  value     = module.cluster.kubeconfig
}
