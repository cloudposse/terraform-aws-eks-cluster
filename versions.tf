terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.42.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.1.0, != 4.0.0"
    }
  }
}
