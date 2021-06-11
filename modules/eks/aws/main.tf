locals {
  base_domain                       = var.base_domain
  kubernetes_host                   = data.aws_eks_cluster.cluster.endpoint
  kubernetes_cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  kubernetes_token                  = data.aws_eks_cluster_auth.cluster.token
  kubeconfig                        = module.cluster.kubeconfig
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.this.id

  tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.this.id

  tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

data "aws_nat_gateway" "this" {
  for_each  = data.aws_subnet_ids.public.ids
  subnet_id = each.value
  state     = "available"
}

data "aws_eks_cluster" "cluster" {
  name = module.cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.cluster.cluster_id
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_host
    cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
    token                  = local.kubernetes_token
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
  token                  = local.kubernetes_token
}

provider "kubernetes-alpha" {
  host                   = local.kubernetes_host
  client_certificate     = local.kubernetes_client_certificate
  client_key             = local.kubernetes_client_key
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
}

locals {
  ingress_worker_group = merge(var.worker_groups.0, { target_group_arns = concat(module.nlb.target_group_arns, module.nlb_private.target_group_arns) })
}

module "cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "15.1.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access_cidrs = concat(
    [
      for nat_gateway in data.aws_nat_gateway.this :
      format("%s/32", nat_gateway.public_ip)
    ],
    var.cluster_endpoint_public_access_cidrs
  )

  subnets          = data.aws_subnet_ids.private.ids
  vpc_id           = var.vpc_id
  enable_irsa      = true
  write_kubeconfig = false
  map_roles        = var.map_roles

  worker_groups = concat([local.ingress_worker_group], try(slice(var.worker_groups, 1, length(var.worker_groups)), []))

  kubeconfig_aws_authenticator_command      = var.kubeconfig_aws_authenticator_command
  kubeconfig_aws_authenticator_command_args = var.kubeconfig_aws_authenticator_command_args
}

resource "aws_security_group_rule" "workers_ingress_healthcheck_https" {
  security_group_id = module.cluster.worker_security_group_id
  type              = "ingress"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
}
resource "aws_security_group_rule" "workers_ingress_healthcheck_http" {
  security_group_id = module.cluster.worker_security_group_id
  type              = "ingress"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
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
  argocd_server_secretkey = var.argocd_server_secretkey

  cluster_issuer = "letsencrypt-prod"
  oidc = var.oidc != null ? var.oidc : {
    issuer_url              = format("https://cognito-idp.%s.amazonaws.com/%s", data.aws_region.current.name, var.cognito_user_pool_id)
    oauth_url               = format("https://%s.auth.%s.amazoncognito.com/oauth2/authorize", var.cognito_user_pool_domain, data.aws_region.current.name)
    token_url               = format("https://%s.auth.%s.amazoncognito.com/oauth2/token", var.cognito_user_pool_domain, data.aws_region.current.name)
    api_url                 = format("https://%s.auth.%s.amazoncognito.com/oauth2/userInfo", var.cognito_user_pool_domain, data.aws_region.current.name)
    client_id               = aws_cognito_user_pool_client.client.0.id
    client_secret           = aws_cognito_user_pool_client.client.0.client_secret
    oauth2_proxy_extra_args = []
  }
  loki = {
    bucket_name = aws_s3_bucket.loki.id,
  }

  grafana = {
    admin_password = local.grafana_admin_password
  }

  cluster_autoscaler = {
    enable = var.enable_cluster_autoscaler
  }

  app_of_apps_values_overrides = [
    templatefile("${path.module}/values.tmpl.yaml",
      {
        aws_default_region              = data.aws_region.current.name
        cert_manager_assumable_role_arn = module.iam_assumable_role_cert_manager.iam_role_arn,
        loki_assumable_role_arn         = module.iam_assumable_role_loki.iam_role_arn,
        loki_bucket_name                = aws_s3_bucket.loki.id,
        enable_efs                      = var.enable_efs
        efs_filesystem_id               = var.enable_efs ? module.efs.0.this_efs_mount_target_file_system_id : ""
        efs_dns_name                    = var.enable_efs ? module.efs.0.this_efs_mount_target_full_dns_name : ""
        cluster_name                    = var.cluster_name
        cluster_autoscaler_role_arn     = var.enable_cluster_autoscaler ? module.iam_assumable_role_cluster_autoscaler[0].iam_role_arn : ""
      }
    ),
    var.app_of_apps_values_overrides,
  ]

  depends_on = [
    module.cluster,
  ]
}
