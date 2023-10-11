terraform {
  required_version = ">= 1.3.0"

  required_providers {
    # https://github.com/hashicorp/terraform-provider-aws/issues/25335
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.1.0, != 4.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 2.0"
    }
  }
}
