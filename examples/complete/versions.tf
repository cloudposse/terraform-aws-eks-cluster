terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.38"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      # Limited the provider to versions less than `2.25.0` since major changes were introduced in `2.25.0` that broke the `terraform-aws-eks-cluster` module.
      # The `kubernetes` provider was updated to use the `terraform-plugin-framework`, which does not support computed lists in the `exec` block:
      # dynamic "exec" {
      #   content {
      #    args = concat(local.exec_profile, ["eks", "get-token", "--cluster-name", try(aws_eks_cluster.default[0].id, "deleted")], local.exec_role)
      #   }
      # }
      # Processing the computed `args` list throws the error:
      # Target Type: []struct { Args []basetypes.StringValue "tfsdk:\"args\"" }
      # Suggested Type: basetypes.ListValue
      #
      # https://github.com/hashicorp/terraform-provider-kubernetes/blob/main/CHANGELOG.md
      # https://github.com/hashicorp/terraform-provider-kubernetes/pull/2347
      # https://github.com/hashicorp/terraform-plugin-framework/issues/713
      version = ">= 2.7.1, < 2.25.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 2.0"
    }
  }
}
