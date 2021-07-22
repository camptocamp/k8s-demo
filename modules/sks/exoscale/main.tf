locals {
  base_domain = coalesce(var.base_domain, format("%s.nip.io", replace(exoscale_nlb.this.ip_address, ".", "-")))

  kubeconfig = module.cluster.kubeconfig
  context    = yamldecode(module.cluster.kubeconfig)

  kubernetes = {
    host                   = local.context.clusters.0.cluster.server
    client_certificate     = base64decode(local.context.users.0.user.client-certificate-data)
    client_key             = base64decode(local.context.users.0.user.client-key-data)
    cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
  }

  default_nodepools = {
    "router-${var.cluster_name}" = {
      size          = 2
      instance_type = "small"
    },
    "devops-stack-${var.cluster_name}" = {
      size          = 2
      instance_type = "large"
    },
  }

  router_nodepool = coalesce(var.router_nodepool, "router-${var.cluster_name}")
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes.host
    client_certificate     = local.kubernetes.client_certificate
    client_key             = local.kubernetes.client_key
    cluster_ca_certificate = local.kubernetes.cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = local.kubernetes.host
  client_certificate     = local.kubernetes.client_certificate
  client_key             = local.kubernetes.client_key
  cluster_ca_certificate = local.kubernetes.cluster_ca_certificate
}

module "cluster" {
  source  = "camptocamp/sks/exoscale"
  version = "0.3.0"

  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  zone               = var.zone

  nodepools = coalesce(var.nodepools, local.default_nodepools)
}

resource "exoscale_nlb" "this" {
  zone = var.zone
  name = format("ingresses-%s", var.cluster_name)
}

resource "exoscale_nlb_service" "http" {
  zone             = exoscale_nlb.this.zone
  name             = "ingress-contoller-http"
  nlb_id           = exoscale_nlb.this.id
  instance_pool_id = module.cluster.nodepools[local.router_nodepool].instance_pool_id
  protocol         = "tcp"
  port             = 80
  target_port      = 80
  strategy         = "round-robin"

  healthcheck {
    mode     = "tcp"
    port     = 80
    interval = 5
    timeout  = 3
    retries  = 1
  }
}

resource "exoscale_nlb_service" "https" {
  zone             = exoscale_nlb.this.zone
  name             = "ingress-contoller-https"
  nlb_id           = exoscale_nlb.this.id
  instance_pool_id = module.cluster.nodepools[local.router_nodepool].instance_pool_id
  protocol         = "tcp"
  port             = 443
  target_port      = 443
  strategy         = "round-robin"

  healthcheck {
    mode     = "tcp"
    port     = 443
    interval = 5
    timeout  = 3
    retries  = 1
  }
}

resource "exoscale_security_group_rule" "http" {
  security_group_id = module.cluster.this_security_group_id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0"
  start_port        = 80
  end_port          = 80
}

resource "exoscale_security_group_rule" "https" {
  security_group_id = module.cluster.this_security_group_id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0"
  start_port        = 443
  end_port          = 443
}

resource "exoscale_security_group_rule" "all" {
  security_group_id      = module.cluster.this_security_group_id
  user_security_group_id = module.cluster.this_security_group_id
  type                   = "INGRESS"
  protocol               = "TCP"
  start_port             = 1
  end_port               = 65535
}

module "argocd" {
  source = "../../argocd-helm"

  kubeconfig              = local.kubeconfig
  repo_url                = var.repo_url
  target_revision         = var.target_revision
  extra_apps              = var.extra_apps
  cluster_name            = var.cluster_name
  base_domain             = local.base_domain
  argocd_server_secretkey = var.argocd_server_secretkey
  cluster_issuer          = "letsencrypt-prod"

  oidc = var.oidc != null ? var.oidc : {
    issuer_url    = format("https://keycloak.apps.%s/auth/realms/kubernetes", local.base_domain)
    oauth_url     = format("https://keycloak.apps.%s/auth/realms/kubernetes/protocol/openid-connect/auth", local.base_domain)
    token_url     = format("https://keycloak.apps.%s/auth/realms/kubernetes/protocol/openid-connect/token", local.base_domain)
    api_url       = format("https://keycloak.apps.%s/auth/realms/kubernetes/protocol/openid-connect/userinfo", local.base_domain)
    client_id     = "applications"
    client_secret = random_password.clientsecret.result

    oauth2_proxy_extra_args = []
  }

  grafana = {
    admin_password = local.grafana_admin_password
  }

  keycloak = {
    enable         = true
    admin_password = random_password.admin_password.result
  }

  loki = {
    bucket_name = "loki"
  }

  app_of_apps_values_overrides = [
    templatefile("${path.module}/values.tmpl.yaml", {}),
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

resource "random_password" "admin_password" {
  length  = 16
  special = false
}
