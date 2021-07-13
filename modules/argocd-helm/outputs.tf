output "argocd_server" {
  description = "The URL of the ArgoCD server."
  value       = format("%s:443", data.kubernetes_ingress.argocd_server.spec.0.rule.0.host)
}

output "argocd_auth_token" {
  description = "The token to set in ARGOCD_AUTH_TOKEN environment variable."
  value       = jwt_hashed_token.argocd.token
}

output "app_of_apps_values" {
  description = "App of Apps values"
  sensitive   = true
  value       = helm_release.app_of_apps.values
}
