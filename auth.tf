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


locals {
  certificate_authority_data_list          = coalescelist(aws_eks_cluster.default.*.certificate_authority, [[{ data : "" }]])
  certificate_authority_data_list_internal = local.certificate_authority_data_list[0]
  certificate_authority_data_map           = local.certificate_authority_data_list_internal[0]
  certificate_authority_data               = local.certificate_authority_data_map["data"]

  cluster_name = join("", aws_eks_cluster.default.*.id)

  # Add worker nodes role ARNs (could be from many worker groups) to the ConfigMap
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

  map_worker_roles_yaml            = trimspace(yamlencode(local.map_worker_roles))
  map_additional_iam_roles_yaml    = trimspace(yamlencode(var.map_additional_iam_roles))
  map_additional_iam_users_yaml    = trimspace(yamlencode(var.map_additional_iam_users))
  map_additional_aws_accounts_yaml = trimspace(yamlencode(var.map_additional_aws_accounts))
}

# Configure `kubeconfig` with prepopulated server and certificate authority data values for the cluster
# https://docs.aws.amazon.com/cli/latest/reference/eks/update-kubeconfig.html
# It will place `kubeconfig` into the default location (specified by `KUBECONFIG` env variable)
# and will be used by terraform kubernetes provider
resource "null_resource" "configure_kubeconfig" {
  count = var.enabled && var.apply_config_map_aws_auth ? 1 : 0

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name=${local.cluster_name} --region=${var.region}"
  }

  triggers = {
    cluster_updated                 = join("", aws_eks_cluster.default.*.id)
    worker_roles_updated            = local.map_worker_roles_yaml
    additional_roles_updated        = local.map_additional_iam_roles_yaml
    additional_users_updated        = local.map_additional_iam_users_yaml
    additional_aws_accounts_updated = local.map_additional_aws_accounts_yaml
  }

  depends_on = [aws_eks_cluster.default]
}

resource "kubernetes_config_map" "iam_nodes_config_map" {
  count = var.enabled && var.apply_config_map_aws_auth ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<-EOT
      ${local.map_worker_roles_yaml}
      %{if local.map_additional_iam_roles_yaml != "[]"}
      ${local.map_additional_iam_roles_yaml}
      %{endif}
      %{if local.map_additional_iam_users_yaml != "[]"}
      mapUsers: |-
      ${local.map_additional_iam_users_yaml}
      %{endif}
      %{if local.map_additional_aws_accounts_yaml != "[]"}
      mapAccounts: |-
      ${local.map_additional_aws_accounts_yaml}
      %{endif}
    EOT
  }

  depends_on = [aws_eks_cluster.default, null_resource.configure_kubeconfig]
}
