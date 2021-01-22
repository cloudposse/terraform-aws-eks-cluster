terraform {
  required_version = ">= 0.12.26"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 1.3"
    }
    kubernetes = {
      # Version 2.0 has breaking changes, this module needs conversion to use it.
      # After converting to 2.0, restore the provider-pinning Bats test in test/Makefile
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}
