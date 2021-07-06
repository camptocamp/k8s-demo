terraform {
  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = "1.24.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.0.2"
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
