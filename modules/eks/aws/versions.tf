terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "3.37.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.0.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.1.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.0.0"
    }
  }

  required_version = ">= 0.13"
}
