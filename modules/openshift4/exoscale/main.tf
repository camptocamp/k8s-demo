locals {
  base_domain = var.base_domain

  kube_admin_config                 = yamldecode(module.cluster.kubeconfig)
  kubernetes_host                   = local.kube_admin_config.clusters.0.cluster.server
  kubernetes_client_certificate     = base64decode(local.kube_admin_config.users.0.user.client-certificate-data)
  kubernetes_client_key             = base64decode(local.kube_admin_config.users.0.user.client-key-data)
  kubernetes_cluster_ca_certificate = base64decode(local.kube_admin_config.clusters.0.cluster.certificate-authority-data)

  kubeconfig = module.cluster.kubeconfig
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_host
    client_certificate     = local.kubernetes_client_certificate
    client_key             = local.kubernetes_client_key
    cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  client_certificate     = local.kubernetes_client_certificate
  client_key             = local.kubernetes_client_key
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
  load_config_file       = false
}

module "cluster" {
  source  = "camptocamp/openshift4/exoscale"
  version = "0.3.0"

  template_id = var.template_id

  base_domain  = var.base_domain
  cluster_name = var.cluster_name
  zone         = var.zone

  bootstrap   = var.bootstrap
  pull_secret = var.pull_secret
  ssh_key     = var.ssh_key

  worker_groups = var.worker_groups
}

module "argocd" {
  source = "../../argocd-helm"

  repo_url        = var.repo_url
  target_revision = var.target_revision
  extra_apps      = var.extra_apps
  cluster_name    = var.cluster_name
  base_domain     = var.base_domain
  cluster_issuer  = "letsencrypt-prod"

  oidc = {}

  app_of_apps_values_overrides = [
    templatefile("${path.module}/values.tmpl.yaml", {}),
    var.app_of_apps_values_overrides,
  ]

  depends_on = [
    module.cluster,
  ]
}
