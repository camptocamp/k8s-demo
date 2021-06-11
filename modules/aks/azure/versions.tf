terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "1.5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.62.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.0.2"
    }
    kubernetes-alpha = {
      source  = "hashicorp/kubernetes-alpha"
      version = "0.5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.0.0"
    }
  }

  required_version = ">= 0.13"
}
