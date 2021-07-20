variable "cluster_name" {
  description = "The name of the Kubernetes cluster to create."
  type        = string
}

variable "repo_url" {
  description = "The source repo URL of ArgoCD's app of apps."
  type        = string
  default     = "https://github.com/camptocamp/devops-stack.git"
}

variable "target_revision" {
  description = "The source target revision of ArgoCD's app of apps."
  type        = string
  default     = "master"
}

variable "app_of_apps_values_overrides" {
  description = "App of apps values overrides."
  type        = string
  default     = ""
}

variable "extra_apps" {
  description = "Extra Applications objects to deploy."
  type        = list(any)
  default     = []
}

variable "extra_app_projects" {
  description = "Extra AppProjects objects to deploy."
  type        = list(any)
  default     = []
}

variable "extra_application_sets" {
  description = "Extra ApplicationSets objects to deploy."
  type        = list(any)
  default     = []
}

variable "oidc" {
  description = "OIDC configuration for core applications."
  type = object({
    issuer_url              = string
    oauth_url               = string
    token_url               = string
    api_url                 = string
    client_id               = string
    client_secret           = string
    oauth2_proxy_extra_args = list(string)
  })
  default = null
}

variable "argocd_server_secretkey" {
  description = "ArgoCD Server Secert Key to avoid regenerate token on redeploy."
  type        = string
  default     = null
}

variable "grafana_admin_password" {
  description = "The admin password for Grafana."
  type        = string
  default     = null
}

variable "grafana_generic_oauth_extra_args" {
  description = "override default oauth value(s)"
  type        = map(string)
  default = {
    autoassign_org_role       = "Editor"
  }
}

variable "repositories" {
  description = "A list of repositories to add to ArgoCD."
  type        = map(string)
  default     = {}
}
