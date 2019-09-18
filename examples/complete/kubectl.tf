###########################################################################################################################################
#
# NOTE: To automatically apply the Kubernetes configuration to the cluster (which allows the worker nodes to join the cluster),
# the requirements outlined here must be met:
# https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#preparation
# https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#configuring-kubectl-for-eks
# https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#required-kubernetes-configuration-to-join-worker-nodes
#
# If you want to automatically apply the Kubernetes configuration, set `var.apply_config_map_aws_auth` to "true"
#
###########################################################################################################################################

locals {
  kubeconfig_filename          = "${path.module}/kubeconfig${var.delimiter}${module.eks_cluster.eks_cluster_id}.yaml"
  config_map_aws_auth_filename = "${path.module}/config-map-aws-auth${var.delimiter}${module.eks_cluster.eks_cluster_id}.yaml"
}

resource "local_file" "kubeconfig" {
  count    = var.enabled == "true" && var.apply_config_map_aws_auth == "true" ? 1 : 0
  content  = module.eks_cluster.kubeconfig
  filename = local.kubeconfig_filename
}

resource "local_file" "config_map_aws_auth" {
  count    = var.enabled == "true" && var.apply_config_map_aws_auth == "true" ? 1 : 0
  content  = module.eks_workers.config_map_aws_auth
  filename = local.config_map_aws_auth_filename
}

resource "null_resource" "apply_config_map_aws_auth" {
  count = var.enabled == "true" && var.apply_config_map_aws_auth == "true" ? 1 : 0

  provisioner "local-exec" {
    command = "${local.set_context} && kubectl apply -f ${local.config_map_aws_auth_filename}"
  }

  triggers = {
    kubeconfig_rendered          = module.eks_cluster.kubeconfig
    config_map_aws_auth_rendered = module.eks_workers.config_map_aws_auth
  }
}
