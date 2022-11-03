terraform {
  required_version = ">= 1.0.0"

  required_providers {
    # https://github.com/hashicorp/terraform-provider-aws/issues/25335
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.38, !=4.18.0, !=4.19.0, !=4.20.0, !=4.21.0, !=4.22.0, !=4.23.0, !=4.24.0, !=4.25.0, !=4.26.0, !=4.27.0, !=4.28.0, !=4.29.0, !=4.30.0, !=4.31.0, !=4.32.0"
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
