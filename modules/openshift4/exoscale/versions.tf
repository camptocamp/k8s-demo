terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.24.1"
    }
    exoscale = {
      source  = "exoscale/exoscale"
      version = "0.21.0"
    }
    ignition = {
      source  = "community-terraform-providers/ignition"
      version = "2.1.1"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "1.13.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.0.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.1"
    }
  }
}
