output "kubeconfig" {
  value     = module.cluster.kubeconfig
  sensitive = true
}

output "grafana_admin_password" {
  value     = module.cluster.grafana_admin_password
  sensitive = true
}
