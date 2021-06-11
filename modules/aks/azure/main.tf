locals {
  base_domain                       = var.base_domain
  kubernetes_host                   = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.host
  kubernetes_username               = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.username
  kubernetes_password               = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.password
  kubernetes_client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.client_certificate)
  kubernetes_client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.client_key)
  kubernetes_cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.cluster_ca_certificate)

  azure_dns_label_name = format("%s-%s", var.cluster_name, replace(var.base_domain, ".", "-"))
  kubeconfig           = data.azurerm_kubernetes_cluster.cluster.kube_admin_config_raw
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_host
    username               = local.kubernetes_username
    password               = local.kubernetes_password
    client_certificate     = local.kubernetes_client_certificate
    client_key             = local.kubernetes_client_key
    cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  username               = local.kubernetes_username
  password               = local.kubernetes_password
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

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

data "azurerm_kubernetes_cluster" "cluster" {
  name                = format("%s-aks", var.cluster_name)
  resource_group_name = data.azurerm_resource_group.this.name

  depends_on = [
    module.cluster,
  ]
}

module "cluster" {
  source  = "Azure/aks/azurerm"
  version = "4.7.0"

  kubernetes_version   = var.kubernetes_version
  orchestrator_version = var.kubernetes_version

  resource_group_name = data.azurerm_resource_group.this.name
  prefix              = var.cluster_name
  network_plugin      = "azure"
  vnet_subnet_id      = var.vnet_subnet_id
  agents_count        = var.agents_count
  agents_size         = var.agents_size
  agents_max_pods     = var.agents_max_pods
  os_disk_size_gb     = var.os_disk_size_gb

  public_ssh_key = var.public_ssh_key

  enable_role_based_access_control = true
  rbac_aad_managed                 = true

  rbac_aad_admin_group_object_ids = var.admin_group_object_ids

  enable_kube_dashboard           = false
  enable_azure_policy             = true
  enable_http_application_routing = false
  enable_log_analytics_workspace  = false
}

module "argocd" {
  source = "../../argocd-helm"

  kubeconfig              = local.kubeconfig
  repo_url                = var.repo_url
  target_revision         = var.target_revision
  extra_apps              = var.extra_apps
  extra_app_projects      = var.extra_app_projects
  extra_application_sets  = var.extra_application_sets
  cluster_name            = var.cluster_name
  base_domain             = var.base_domain
  cluster_issuer          = "letsencrypt-prod"
  argocd_server_secretkey = var.argocd_server_secretkey

  oidc = var.oidc != null ? var.oidc : {
    issuer_url              = format("https://login.microsoftonline.com/%s/v2.0", data.azurerm_client_config.current.tenant_id)
    oauth_url               = format("https://login.microsoftonline.com/%s/oauth2/authorize", data.azurerm_client_config.current.tenant_id)
    token_url               = format("https://login.microsoftonline.com/%s/oauth2/token", data.azurerm_client_config.current.tenant_id)
    api_url                 = format("https://graph.microsoft.com/oidc/userinfo")
    client_id               = azuread_application.oauth2_apps.0.application_id
    client_secret           = azuread_application_password.oauth2_apps.0.value
    oauth2_proxy_extra_args = []
  }

  grafana = {
    admin_password = local.grafana_admin_password
  }

  app_of_apps_values_overrides = [
    templatefile("${path.module}/values.tmpl.yaml",
      {
        subscription_id                              = split("/", data.azurerm_subscription.primary.id)[2]
        resource_group_name                          = var.resource_group_name
        base_domain                                  = var.base_domain
        cert_manager_resource_id                     = azurerm_user_assigned_identity.cert_manager.id
        cert_manager_client_id                       = azurerm_user_assigned_identity.cert_manager.client_id
        azure_dns_label_name                         = local.azure_dns_label_name
        kube_prometheus_stack_prometheus_resource_id = azurerm_user_assigned_identity.kube_prometheus_stack_prometheus.id
        kube_prometheus_stack_prometheus_client_id   = azurerm_user_assigned_identity.kube_prometheus_stack_prometheus.client_id
        loki_container_name                          = azurerm_storage_container.loki.name
        loki_account_name                            = azurerm_storage_account.this.name
        loki_account_key                             = azurerm_storage_account.this.primary_access_key
      }
    ),
    var.app_of_apps_values_overrides,
  ]

  depends_on = [
    module.cluster,
  ]
}

data "azurerm_subscription" "primary" {
}

resource "azurerm_role_assignment" "managed_identity_operator" {
  scope                = format("%s/resourcegroups/%s", data.azurerm_subscription.primary.id, module.cluster.node_resource_group)
  role_definition_name = "Managed Identity Operator"
  principal_id         = lookup(module.cluster.kubelet_identity[0], "object_id")
}

resource "azurerm_role_assignment" "virtual_machine_contributor" {
  scope                = format("%s/resourcegroups/%s", data.azurerm_subscription.primary.id, module.cluster.node_resource_group)
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = lookup(module.cluster.kubelet_identity[0], "object_id")
}

resource "azurerm_user_assigned_identity" "kube_prometheus_stack_prometheus" {
  resource_group_name = module.cluster.node_resource_group
  location            = data.azurerm_resource_group.this.location
  name                = "kube-prometheus-stack-prometheus"
}

resource "azurerm_user_assigned_identity" "cert_manager" {
  resource_group_name = module.cluster.node_resource_group
  location            = data.azurerm_resource_group.this.location
  name                = "cert-manager"
}

resource "random_string" "storage_account" {
  length  = 24
  lower   = true
  upper   = false
  special = false
}

resource "azurerm_storage_account" "this" {
  name                     = random_string.storage_account.result
  resource_group_name      = module.cluster.node_resource_group
  location                 = data.azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "loki" {
  name                  = "loki"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# TODO: I'm not sure this is required
resource "azurerm_role_assignment" "reader" {
  scope                = format("%s/resourcegroups/%s", data.azurerm_subscription.primary.id, module.cluster.node_resource_group)
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.cert_manager.principal_id
}

data "azurerm_dns_zone" "this" {
  name                = var.base_domain
  resource_group_name = var.resource_group_name
}

resource "azurerm_dns_cname_record" "wildcard" {
  name                = "*.apps.${var.cluster_name}"
  zone_name           = data.azurerm_dns_zone.this.name
  resource_group_name = data.azurerm_dns_zone.this.resource_group_name
  ttl                 = 300
  record              = "${local.azure_dns_label_name}.${data.azurerm_resource_group.this.location}.cloudapp.azure.com."
}

resource "azurerm_role_assignment" "dns_zone_contributor" {
  scope                = data.azurerm_dns_zone.this.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.cert_manager.principal_id
}

data "azurerm_client_config" "current" {}

resource "azuread_application" "oauth2_apps" {
  count = var.oidc == null ? 1 : 0

  name = "oauth2-apps-${var.cluster_name}"
  reply_urls = [
    format("https://argocd.apps.%s.%s/auth/callback", var.cluster_name, var.base_domain),
    format("https://grafana.apps.%s.%s/login/generic_oauth", var.cluster_name, var.base_domain),
    format("https://prometheus.apps.%s.%s/oauth2/callback", var.cluster_name, var.base_domain),
    format("https://alertmanager.apps.%s.%s/oauth2/callback", var.cluster_name, var.base_domain),
  ]

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }

  group_membership_claims = "ApplicationGroup"

  optional_claims {
    access_token {
      additional_properties = []
      essential             = false
      name                  = "groups"
    }
    id_token {
      additional_properties = []
      essential             = false
      name                  = "groups"
    }
  }
}

resource "azuread_application_app_role" "argocd_admin" {
  count = var.oidc == null ? 1 : 0

  application_object_id = azuread_application.oauth2_apps.0.id
  allowed_member_types  = ["User"]
  description           = "ArgoCD Admins"
  display_name          = "ArgoCD Administrator"
  is_enabled            = true
  value                 = "argocd-admin"
}

resource "random_password" "oauth2_apps" {
  count = var.oidc == null ? 1 : 0

  length           = 34
  special          = true
  override_special = "-_~."
}

resource "azuread_application_password" "oauth2_apps" {
  count = var.oidc == null ? 1 : 0

  application_object_id = azuread_application.oauth2_apps.0.id
  end_date              = "2299-12-30T23:00:00Z"
  value                 = random_password.oauth2_apps.0.result
}

data "azurerm_policy_set_definition" "restricted" {
  display_name = "Kubernetes cluster pod security restricted standards for Linux-based workloads"
}

data "azurerm_policy_set_definition" "baseline" {
  display_name = "Kubernetes cluster pod security baseline standards for Linux-based workloads"
}

resource "azurerm_policy_assignment" "baseline" {
  name                 = "${var.cluster_name}-baseline"
  scope                = format("%s/resourcegroups/%s", data.azurerm_subscription.primary.id, data.azurerm_resource_group.this.name)
  policy_definition_id = data.azurerm_policy_set_definition.baseline.id
  parameters           = <<PARAMETERS
{
  "effect": {
    "value": "deny"
  },
  "excludedNamespaces": {
    "value": [
      "aad-pod-identity",
      "kube-prometheus-stack",
      "loki-stack",
      "csi-secrets-store-provider-azure",
      "kube-system",
      "gatekeeper-system",
      "azure-arc,aad-pod-identity"
    ]
  }
}
PARAMETERS

}
