output "base_domain" {
  value = module.cluster.base_domain
}

output "argocd_auth_token" {
  sensitive = true
  value     = module.cluster.argocd_auth_token
}

output "kubeconfig" {
  sensitive = true
  value     = module.cluster.kubeconfig
}

output "admin_password" {
  sensitive = true
  value     = module.cluster.admin_password
}

output "grafana_admin_password" {
  sensitive = true
  value     = module.cluster.grafana_admin_password
}
