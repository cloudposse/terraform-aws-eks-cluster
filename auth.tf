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
  yaml_quote = var.aws_auth_yaml_strip_quotes ? "" : "\""

  need_kubernetes_provider = local.enabled && var.apply_config_map_aws_auth

  kubeconfig_path_enabled = local.need_kubernetes_provider && var.kubeconfig_path_enabled
  kube_exec_auth_enabled  = local.kubeconfig_path_enabled ? false : local.need_kubernetes_provider && var.kube_exec_auth_enabled
  kube_data_auth_enabled  = local.kube_exec_auth_enabled ? false : local.need_kubernetes_provider && var.kube_data_auth_enabled

  exec_profile = local.kube_exec_auth_enabled && var.kube_exec_auth_aws_profile_enabled ? ["--profile", var.kube_exec_auth_aws_profile] : []
  exec_role    = local.kube_exec_auth_enabled && var.kube_exec_auth_role_arn_enabled ? ["--role-arn", var.kube_exec_auth_role_arn] : []

  cluster_endpoint_data     = join("", aws_eks_cluster.default[*].endpoint) # use `join` instead of `one` to keep the value a string
  cluster_auth_map_endpoint = var.apply_config_map_aws_auth ? local.cluster_endpoint_data : var.dummy_kubeapi_server

  certificate_authority_data_list          = coalescelist(aws_eks_cluster.default[*].certificate_authority, [[{ data : "" }]])
  certificate_authority_data_list_internal = local.certificate_authority_data_list[0]
  certificate_authority_data_map           = local.certificate_authority_data_list_internal[0]
  certificate_authority_data               = local.certificate_authority_data_map["data"]

  # Add worker nodes role ARNs (could be from many un-managed worker groups) to the ConfigMap
  # Note that we don't need to do this for managed Node Groups since EKS adds their roles to the ConfigMap automatically
  map_worker_roles = [
    for role_arn in var.workers_role_arns : {
      rolearn  = role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes"
      ]
    }
  ]

  previous_map_additional_iam_roles = jsondecode(try(data.aws_secretsmanager_secret_version.previous[0].secret_string, "[]"))
  cluster_current_map_roles         = try(yamldecode(data.kubernetes_config_map.existing_aws_auth.data["mapRoles"]), [])

  # Check the "map_additional_iam_roles" from last terraform apply to know if we need to remove any roles
  roles_removed_from_tf_input = setsubtract(local.previous_map_additional_iam_roles, var.map_additional_iam_roles)

  # Ordering is important here as new items are appended to the config map by AWS
  merged_roles = distinct(concat(
    local.map_worker_roles,
    local.cluster_current_map_roles,
    var.map_additional_iam_roles
  ))

  # Manual filtering instead of setsubtract since ordering is lost so terraform always reports changes to the config map
  cluster_map_roles = [
    for item in local.merged_roles : item if contains(local.roles_removed_from_tf_input, item) == false
  ]
}

resource "null_resource" "wait_for_cluster" {
  count      = local.enabled && var.apply_config_map_aws_auth ? 1 : 0
  depends_on = [aws_eks_cluster.default]

  provisioner "local-exec" {
    command     = var.wait_for_cluster_command
    interpreter = var.local_exec_interpreter
    environment = {
      ENDPOINT = local.cluster_endpoint_data
    }
  }
}


# Get an authentication token to communicate with the EKS cluster.
# By default (before other roles are added to the Auth ConfigMap), you can authenticate to EKS cluster only by assuming the role that created the cluster.
# `aws_eks_cluster_auth` uses IAM credentials from the AWS provider to generate a temporary token.
# If the AWS provider assumes an IAM role, `aws_eks_cluster_auth` will use the same IAM role to get the auth token.
# https://www.terraform.io/docs/providers/aws/d/eks_cluster_auth.html
#
# You can set `kube_exec_auth_enabled` to use a different IAM Role or AWS config profile to fetch the auth token
#
data "aws_eks_cluster_auth" "eks" {
  count = local.kube_data_auth_enabled ? 1 : 0
  name  = one(aws_eks_cluster.default[*].id)
}


provider "kubernetes" {
  # Without a dummy API server configured, the provider will throw an error and prevent a "plan" from succeeding
  # in situations where Terraform does not provide it with the cluster endpoint before triggering an API call.
  # Since those situations are limited to ones where we do not care about the failure, such as fetching the
  # ConfigMap before the cluster has been created or in preparation for deleting it, and the worst that will
  # happen is that the aws-auth ConfigMap will be unnecessarily updated, it is just better to ignore the error
  # so we can proceed with the task of creating or destroying the cluster.
  #
  # If this solution bothers you, you can disable it by setting var.dummy_kubeapi_server = null
  host                   = local.cluster_auth_map_endpoint
  cluster_ca_certificate = local.enabled && !local.kubeconfig_path_enabled ? base64decode(local.certificate_authority_data) : null
  token                  = local.kube_data_auth_enabled ? one(data.aws_eks_cluster_auth.eks[*].token) : null
  # The Kubernetes provider will use information from KUBECONFIG if it exists, but if the default cluster
  # in KUBECONFIG is some other cluster, this will cause problems, so we override it always.
  config_path    = local.kubeconfig_path_enabled ? var.kubeconfig_path : ""
  config_context = var.kubeconfig_context

  dynamic "exec" {
    for_each = local.kube_exec_auth_enabled && length(local.cluster_endpoint_data) > 0 ? ["exec"] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = concat(local.exec_profile, ["eks", "get-token", "--cluster-name", try(aws_eks_cluster.default[0].id, "deleted")], local.exec_role)
    }
  }
}

data "kubernetes_config_map" "existing_aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  depends_on = [null_resource.wait_for_cluster[0]]
}

module "secrets_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["map", "additional", "iam", "roles"]

  context = module.this.context
}

resource "aws_secretsmanager_secret" "map_additional_iam_roles" {
  count = local.enabled && var.apply_config_map_aws_auth && var.kubernetes_config_map_ignore_role_changes == false ? 1 : 0

  name        = module.secrets_label.id
  description = "Map additional_iam_roles for ${module.label.id} EKS cluster"

  # Force deletion of secret as we don't want any recovery
  recovery_window_in_days = 0

  tags = module.secrets_label.tags
}

# Need to make sure it exists initially otherwise the data source fails
resource "aws_secretsmanager_secret_version" "initial" {
  count = local.enabled && var.apply_config_map_aws_auth && var.kubernetes_config_map_ignore_role_changes == false ? 1 : 0

  secret_id     = one(aws_secretsmanager_secret.map_additional_iam_roles[*].id)
  secret_string = "[]"

  lifecycle {
    ignore_changes = [
      secret_string,
    ]
  }
}

# Read the previous map_additional_iam_roles
data "aws_secretsmanager_secret_version" "previous" {
  count = local.enabled && var.apply_config_map_aws_auth && var.kubernetes_config_map_ignore_role_changes == false ? 1 : 0

  secret_id  = one(aws_secretsmanager_secret.map_additional_iam_roles[*].id)
  depends_on = [aws_secretsmanager_secret_version.initial]
}


# Save new value for this apply, make sure the data source runs before this writes the new value using depends_on
resource "aws_secretsmanager_secret_version" "current" {
  count = local.enabled && var.apply_config_map_aws_auth && var.kubernetes_config_map_ignore_role_changes == false ? 1 : 0

  secret_id     = one(aws_secretsmanager_secret.map_additional_iam_roles[*].id)
  secret_string = jsonencode(var.map_additional_iam_roles)

  depends_on = [data.aws_secretsmanager_secret_version.previous]
}


resource "kubernetes_config_map" "aws_auth_ignore_changes" {
  count      = local.enabled && var.apply_config_map_aws_auth && var.kubernetes_config_map_ignore_role_changes ? 1 : 0
  depends_on = [null_resource.wait_for_cluster]

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
  depends_on = [null_resource.wait_for_cluster]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles    = replace(yamlencode(local.cluster_map_roles), "\"", local.yaml_quote)
    mapUsers    = replace(yamlencode(var.map_additional_iam_users), "\"", local.yaml_quote)
    mapAccounts = replace(yamlencode(var.map_additional_aws_accounts), "\"", local.yaml_quote)
  }
}
