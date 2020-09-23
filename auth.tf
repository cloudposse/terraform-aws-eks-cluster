# The EKS service does not provide a cluster-level API parameter or resource to automatically configure the underlying Kubernetes cluster
# to allow worker nodes to join the cluster via AWS IAM role authentication.

# NOTE: To automatically apply the Kubernetes configuration to the cluster (which allows the worker nodes to join the cluster),
# the requirements outlined here must be met:
# https://learn.hashicorp.com/terraform/aws/eks-intro#preparation
# https://learn.hashicorp.com/terraform/aws/eks-intro#configuring-kubectl-for-eks
# https://learn.hashicorp.com/terraform/aws/eks-intro#required-kubernetes-configuration-to-join-worker-nodes

# Additional links
# https://learn.hashicorp.com/terraform/aws/eks-intro
# https://itnext.io/how-does-client-authentication-work-on-amazon-eks-c4f2b90d943b
# https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html
# https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
# https://docs.aws.amazon.com/cli/latest/reference/eks/update-kubeconfig.html
# https://docs.aws.amazon.com/en_pv/eks/latest/userguide/create-kubeconfig.html
# https://itnext.io/kubernetes-authorization-via-open-policy-agent-a9455d9d5ceb
# http://marcinkaszynski.com/2018/07/12/eks-auth.html
# https://cloud.google.com/kubernetes-engine/docs/concepts/configmap
# http://yaml-multiline.info
# https://github.com/terraform-providers/terraform-provider-kubernetes/issues/216
# https://www.terraform.io/docs/cloud/run/install-software.html
# https://stackoverflow.com/questions/26123740/is-it-possible-to-install-aws-cli-package-without-root-permission
# https://stackoverflow.com/questions/58232731/kubectl-missing-form-terraform-cloud
# https://docs.aws.amazon.com/cli/latest/userguide/install-bundle.html
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv1.html


locals {
  certificate_authority_data_list          = coalescelist(aws_eks_cluster.default.*.certificate_authority, [[{ data : "" }]])
  certificate_authority_data_list_internal = local.certificate_authority_data_list[0]
  certificate_authority_data_map           = local.certificate_authority_data_list_internal[0]
  certificate_authority_data               = local.certificate_authority_data_map["data"]

  # Add worker nodes role ARNs (could be from many un-managed worker groups) to the ConfigMap
  # Note that we don't need to do this for managed Node Groups since EKS adds their roles to the ConfigMap automatically
  map_worker_roles = [
    for role_arn in var.workers_role_arns : {
      rolearn : role_arn
      username : "system:node:{{EC2PrivateDNSName}}"
      groups : [
        "system:bootstrappers",
        "system:nodes"
      ]
    }
  ]
}

resource "null_resource" "wait_for_cluster" {
  count      = local.enabled && var.apply_config_map_aws_auth ? 1 : 0
  depends_on = [aws_eks_cluster.default[0]]

  provisioner "local-exec" {
    command     = var.wait_for_cluster_command
    interpreter = var.local_exec_interpreter
    environment = {
      ENDPOINT = aws_eks_cluster.default[0].endpoint
    }
  }
}

data "aws_eks_cluster" "eks" {
  count = local.enabled && var.apply_config_map_aws_auth ? 1 : 0
  name  = join("", aws_eks_cluster.default.*.id)
}

# Get an authentication token to communicate with the EKS cluster.
# By default (before other roles are added to the Auth ConfigMap), you can authenticate to EKS cluster only by assuming the role that created the cluster.
# `aws_eks_cluster_auth` uses IAM credentials from the AWS provider to generate a temporary token.
# If the AWS provider assumes an IAM role, `aws_eks_cluster_auth` will use the same IAM role to get the auth token.
# https://www.terraform.io/docs/providers/aws/d/eks_cluster_auth.html
data "aws_eks_cluster_auth" "eks" {
  count = local.enabled && var.apply_config_map_aws_auth ? 1 : 0
  name  = join("", aws_eks_cluster.default.*.id)
}

provider "kubernetes" {
  token                  = join("", data.aws_eks_cluster_auth.eks.*.token)
  host                   = join("", data.aws_eks_cluster.eks.*.endpoint)
  cluster_ca_certificate = base64decode(join("", data.aws_eks_cluster.eks.*.certificate_authority.0.data))
  load_config_file       = var.kubernetes_load_config_file
  config_path            = var.kubernetes_config_path
}

resource "kubernetes_config_map" "aws_auth_ignore_changes" {
  count      = local.enabled && var.apply_config_map_aws_auth && var.kubernetes_config_map_ignore_role_changes ? 1 : 0
  depends_on = [null_resource.wait_for_cluster[0]]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles    = yamlencode(distinct(concat(local.map_worker_roles, var.map_additional_iam_roles)))
    mapUsers    = yamlencode(var.map_additional_iam_users)
    mapAccounts = yamlencode(var.map_additional_aws_accounts)
  }

  lifecycle {
    ignore_changes = [data["mapRoles"]]
  }
}

resource "kubernetes_config_map" "aws_auth" {
  count      = local.enabled && var.apply_config_map_aws_auth && var.kubernetes_config_map_ignore_role_changes == false ? 1 : 0
  depends_on = [null_resource.wait_for_cluster[0]]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles    = yamlencode(distinct(concat(local.map_worker_roles, var.map_additional_iam_roles)))
    mapUsers    = yamlencode(var.map_additional_iam_users)
    mapAccounts = yamlencode(var.map_additional_aws_accounts)
  }
}
