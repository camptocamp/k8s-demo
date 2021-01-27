terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "1.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.34.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "1.13.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.0.2"
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
