###########################################################################################################################################
#
# NOTE: To automatically apply the Kubernetes configuration to the cluster (which allows the worker nodes to join the cluster),
# the requirements outlined here must be met:
# https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#preparation
# https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#configuring-kubectl-for-eks
# https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#required-kubernetes-configuration-to-join-worker-nodes
#
# https://itnext.io/how-does-client-authentication-work-on-amazon-eks-c4f2b90d943b
# https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html
# https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
#
###########################################################################################################################################

provider "kubernetes" {
  host = "https://104.196.242.174"

  username = "username"
  password = "password"
}

locals {
  cluster_endpoint = join("", aws_eks_cluster.default.*.endpoint)
  cluster_name     = join("", aws_eks_cluster.default.*.id)

  kubeconfig_file      = "${path.module}/kubeconfig${var.delimiter}${local.cluster_name}.json"
  config_map_data_file = "${path.module}/config-map-aws-auth${var.delimiter}${local.cluster_name}.json"

  kubeconfig_command = var.cluster_auth_type == "aws-iam-authenticator" ? "aws-iam-authenticator" : "aws"

  kubeconfig_command_args_iam_authenticator = [
    "token",
    "-i",
    local.cluster_name
  ]

  kubeconfig_command_args_sts_token = [
    "eks",
    "get-token",
    "--cluster-name",
    local.cluster_name
  ]

  kubeconfig_command_args = var.cluster_auth_type == "aws-iam-authenticator" ? local.kubeconfig_command_args_iam_authenticator : local.kubeconfig_command_args_sts_token

  kubeconfig = {
    apiVersion : "v1"
    kind : "Config"
    preferences : {}

    clusters : [
      {
        name : local.cluster_name
        cluster : {
          server : local.cluster_endpoint
          certificate-authority-data : local.certificate_authority_data
        }
      }
    ]

    contexts : [
      {
        name : local.cluster_name
        context : {
          cluster : local.cluster_name
          user : local.cluster_name
        }
      }
    ]

    current-context : local.cluster_name

    users : [
      {
        name : local.cluster_name
        user : {
          exec : {
            apiVersion : "client.authentication.k8s.io/v1alpha1"
            command : local.kubeconfig_command
            args : local.kubeconfig_command_args
          }
        }
      }
    ]
  }

  map_worker_roles = flatten([
    for role_arns in var.workers_role_arns : {
      rolearn : role_arns
      username : "system:node:{{EC2PrivateDNSName}}"
      groups : [
        "system:bootstrappers",
        "system:nodes"
      ]
    }
  ])

  # The EKS service does not provide a cluster-level API parameter or resource to automatically configure the underlying Kubernetes cluster
  # to allow worker nodes to join the cluster via AWS IAM role authentication.
  # This is a Kubernetes ConfigMap configuration for worker nodes to join the cluster
  # https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#required-kubernetes-configuration-to-join-worker-nodes
  # https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
  config_map_data = {
    mapUsers : var.map_additional_iam_users,
    mapAccounts : var.map_additional_aws_accounts,
    mapRoles : concat(local.map_worker_roles, var.map_additional_iam_roles)
  }
}

resource "local_file" "kubeconfig_file" {
  count      = var.enabled ? 1 : 0
  content    = jsonencode(local.kubeconfig)
  filename   = local.kubeconfig_file
  depends_on = [aws_eks_cluster.default]
}

resource "local_file" "config_map_data_file" {
  count      = var.enabled && var.apply_config_map_aws_auth ? 1 : 0
  content    = jsonencode(local.config_map_data)
  filename   = local.config_map_data_file
  depends_on = [aws_eks_cluster.default]
}

resource "null_resource" "apply_config_map_aws_auth" {
  count = var.enabled && var.apply_config_map_aws_auth ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      while [[ ! -e ${local.config_map_data_file} || ! -e ${local.kubeconfig_file} ]] ; do sleep 1; done &&
      kubectl create configmap aws-auth --namespace=kube-system --from-file=${local.config_map_data_file} --kubeconfig ${local.kubeconfig_file}
    EOT
  }

  triggers = {
    kubeconfig_ready = jsonencode(local.kubeconfig)
    config_map_aws_auth_ready = jsonencode(local.config_map_data)
  }

  depends_on = [aws_eks_cluster.default]
}
