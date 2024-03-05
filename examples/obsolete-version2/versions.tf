# Because this module is an historical example, not a living one,
# we are pinning provider versions to historical versions that
# are compatible with the module code.
# We ordinarily do not recommend pinning versions in this way.

terraform {
  required_version = ">= 1.3.0, < 1.6.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Version 5.0.0 introduced a lot of changes.
      version = ">= 3.38, < 5.0.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      # Version 2.25.0 introduced a breaking change.
      version = ">= 2.7.1, <= 2.24.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "> 3.1, < 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "> 2.0, < 4.0"
    }
  }
}
