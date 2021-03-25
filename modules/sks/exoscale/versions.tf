terraform {
  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
      version = "0.24.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
  }
}
