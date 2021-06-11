terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.2"
    }
    jwt = {
      source  = "camptocamp/jwt"
      version = ">= 0.0.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.6.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    kubernetes-alpha = {
      source  = "hashicorp/kubernetes-alpha"
      version = "~> 0.5"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 0.13"
}
