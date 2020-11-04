variable "cluster_name" {
  description = "The name of the Kubernetes cluster to create."
  type        = string
}

variable "k3s_version" {
  description = "The K3s version to use"
  type        = string
  default     = "v1.18.10-k3s2"
}

variable "node_count" {
  description = "Number of nodes to deploy"
  type        = number
  default     = 2
}

variable "repo_url" {
  description = "The source repo URL of ArgoCD's app of apps."
  type        = string
}

variable "target_revision" {
  description = "The source target revision of ArgoCD's app of apps."
  type        = string
}

variable "app_of_apps_parameters" {
  description = "App of apps parameters overrides."
  type = list(object({
    name        = string
    value       = string
    forceString = bool
  }))
  default = []
}
