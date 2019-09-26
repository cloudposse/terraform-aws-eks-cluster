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
#
###########################################################################################################################################

locals {
  kubeconfig_filename          = "${path.module}/kubeconfig${var.delimiter}${join("", aws_eks_cluster.default.*.id)}.yaml"
  config_map_aws_auth_filename = "${path.module}/config-map-aws-auth${var.delimiter}${join("", aws_eks_cluster.default.*.id)}.yaml"
}

data "template_file" "kubeconfig" {
  count    = var.enabled ? 1 : 0
  template = file("${path.module}/templates/kubeconfig.tpl")

  vars = {
    server                     = join("", aws_eks_cluster.default.*.endpoint)
    certificate_authority_data = local.certificate_authority_data
    cluster_name               = module.label.id
  }
}

data "template_file" "config_map_aws_auth" {
  count    = var.enabled && var.apply_config_map_aws_auth ? 1 : 0
  template = file("${path.module}/templates/config_map_aws_auth.tpl")

  vars = {
    aws_iam_role_arn = var.workers_role_arns[0]
  }
}

resource "local_file" "kubeconfig" {
  count    = var.enabled && var.apply_config_map_aws_auth ? 1 : 0
  content  = join("", data.template_file.kubeconfig.*.rendered)
  filename = local.kubeconfig_filename
}

resource "local_file" "config_map_aws_auth" {
  count    = var.enabled && var.apply_config_map_aws_auth ? 1 : 0
  content  = join("", data.template_file.config_map_aws_auth.*.rendered)
  filename = local.config_map_aws_auth_filename
}

resource "null_resource" "apply_config_map_aws_auth" {
  count = var.enabled && var.apply_config_map_aws_auth ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl apply -f ${local.config_map_aws_auth_filename} --kubeconfig ${local.kubeconfig_filename}"
  }

  triggers {
    kubeconfig_rendered          = join("", data.template_file.kubeconfig.*.rendered)
    config_map_aws_auth_rendered = join("", data.template_file.config_map_aws_auth.*.rendered)
  }
}
