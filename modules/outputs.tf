output "argocd_auth_token" {
  description = "The token to set in ARGOCD_AUTH_TOKEN environment variable."
  value       = module.argocd.argocd_auth_token
  sensitive   = true
}

output "kubeconfig" {
  description = "The content of the KUBECONFIG file."
  value       = local.kubeconfig
  sensitive   = true
}

output "argocd_server" {
  description = "The URL of the ArgoCD server."
  value       = module.argocd.argocd_server
}

output "repo_url" {
  value = var.repo_url
}

output "target_revision" {
  value = var.target_revision
}

output "grafana_admin_password" {
  description = "The admin password for Grafana."
  value       = local.grafana_admin_password
  sensitive   = true
}

output "app_of_apps_values" {
  description = "App of Apps values"
  sensitive   = true
  value       = module.argocd.app_of_apps_values
}
