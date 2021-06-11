locals {
  base_domain = var.base_domain

  kube_admin_config                 = yamldecode(module.cluster.kubeconfig)
  kubernetes_host                   = local.kube_admin_config.clusters.0.cluster.server
  kubernetes_client_certificate     = base64decode(local.kube_admin_config.users.0.user.client-certificate-data)
  kubernetes_client_key             = base64decode(local.kube_admin_config.users.0.user.client-key-data)
  kubernetes_cluster_ca_certificate = base64decode(local.kube_admin_config.clusters.0.cluster.certificate-authority-data)

  kubeconfig = module.cluster.kubeconfig

  grafana_admin_password = var.grafana_admin_password == null ? random_password.grafana_admin_password.0.result : var.grafana_admin_password
}

module "cluster" {
  source  = "camptocamp/openshift4/aws"
  version = "0.1.0"

  install_config_path = var.install_config_path
  base_domain         = var.base_domain
  cluster_name        = var.cluster_name
  region              = var.region
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

}

provider "kubernetes-alpha" {
  host                   = local.kubernetes_host
  client_certificate     = local.kubernetes_client_certificate
  client_key             = local.kubernetes_client_key
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
}

module "argocd" {
  source = "../../argocd-helm"

  kubeconfig             = local.kubeconfig
  repo_url               = var.repo_url
  target_revision        = var.target_revision
  extra_apps             = var.extra_apps
  extra_app_projects     = var.extra_app_projects
  extra_application_sets = var.extra_application_sets
  cluster_name           = var.cluster_name
  base_domain            = var.base_domain
  cluster_issuer         = "letsencrypt-prod"

  oidc = {
    client_secret = random_password.clientsecret.result
  }

  loki = {
    enable = false
  }

  cert_manager = {
    enable = false
  }

  keycloak = {
    enable = false
  }

  kube_prometheus_stack = {
    enable = false
  }

  metrics_server = {
    enable = false
  }

  minio = {
    enable = false
  }

  traefik = {
    enable = false
  }

  app_of_apps_values_overrides = [
    templatefile("${path.module}/values.tmpl.yaml",
      {
        openshift_oauthclient_secret = random_password.clientsecret.result
        cluster_name                 = var.cluster_name
        base_domain                  = var.base_domain
    }),
    var.app_of_apps_values_overrides,
  ]

  depends_on = [
    module.cluster,
  ]
}

resource "random_password" "clientsecret" {
  length  = 16
  special = false
}

resource "random_password" "grafana_admin_password" {
  count = var.grafana_admin_password == null ? 1 : 0

  length  = 16
  special = false
}
