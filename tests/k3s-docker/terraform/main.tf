module "cluster" {
  source = "../../../modules/k3s/docker"

  cluster_name = "default"
  node_count   = 1

  repo_url        = var.repo_url
  target_revision = var.target_revision
}

provider "argocd" {
  server_addr = module.cluster.argocd_server
  auth_token  = module.cluster.argocd_auth_token
  insecure    = true
  grpc_web    = true
}

resource "argocd_project" "demo_app" {
  metadata {
    name      = "demo-app"
    namespace = "argocd"
  }

  spec {
    description  = "Demo application project"
    source_repos = ["*"]

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "default"
    }

    orphaned_resources {
      warn = true
    }
  }
}

resource "argocd_application" "demo_app" {
  metadata {
    name = "demo-app"
  }

  spec {
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "default"
    }

    source {
      repo_url        = var.repo_url
      path            = "tests/k3s-docker/argocd/demo-app"
      target_revision = var.target_revision

      helm {
        values = <<EOT
spec:
  source:
    repoURL: ${var.repo_url}
    targetRevision: ${var.target_revision}

baseDomain: ${module.cluster.base_domain}
EOT
      }
    }

    project = argocd_project.demo_app.metadata.0.name

    sync_policy {
      automated = {
        prune     = true
        self_heal = true
      }
    }
  }

  wait = true
}
