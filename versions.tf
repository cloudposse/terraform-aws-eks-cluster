terraform {
  required_version = ">= 0.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.38"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 1.13"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 2.2.0"
    }
  }
}
