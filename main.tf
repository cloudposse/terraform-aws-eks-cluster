locals {
  enabled = module.this.enabled

  cluster_encryption_config = {
    resources = var.cluster_encryption_config_resources

    provider_key_arn = local.enabled && var.cluster_encryption_config_enabled && var.cluster_encryption_config_kms_key_id == "" ? (
      join("", aws_kms_key.cluster.*.arn)
    ) : var.cluster_encryption_config_kms_key_id
  }
}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["cluster"]

  context = module.this.context
}

data "aws_partition" "current" {
  count = local.enabled ? 1 : 0
}

resource "aws_cloudwatch_log_group" "default" {
  count             = local.enabled && length(var.enabled_cluster_log_types) > 0 ? 1 : 0
  name              = "/aws/eks/${module.label.id}/cluster"
  retention_in_days = var.cluster_log_retention_period
  tags              = module.label.tags
}

resource "aws_kms_key" "cluster" {
  count                   = local.enabled && var.cluster_encryption_config_enabled && var.cluster_encryption_config_kms_key_id == "" ? 1 : 0
  description             = "EKS Cluster ${module.label.id} Encryption Config KMS Key"
  enable_key_rotation     = var.cluster_encryption_config_kms_key_enable_key_rotation
  deletion_window_in_days = var.cluster_encryption_config_kms_key_deletion_window_in_days
  policy                  = var.cluster_encryption_config_kms_key_policy
  tags                    = module.label.tags
}

resource "aws_kms_alias" "cluster" {
  count         = local.enabled && var.cluster_encryption_config_enabled && var.cluster_encryption_config_kms_key_id == "" ? 1 : 0
  name          = format("alias/%v", module.label.id)
  target_key_id = join("", aws_kms_key.cluster.*.key_id)
}

resource "aws_eks_cluster" "default" {
  count                     = local.enabled ? 1 : 0
  name                      = module.label.id
  tags                      = module.label.tags
  role_arn                  = local.eks_service_role_arn
  version                   = var.kubernetes_version
  enabled_cluster_log_types = var.enabled_cluster_log_types

  dynamic "encryption_config" {
    for_each = var.cluster_encryption_config_enabled ? [local.cluster_encryption_config] : []
    content {
      resources = lookup(encryption_config.value, "resources")
      provider {
        key_arn = lookup(encryption_config.value, "provider_key_arn")
      }
    }
  }

  vpc_config {
    security_group_ids      = var.create_security_group ? compact(concat(var.associated_security_group_ids, [join("", aws_security_group.default.*.id)])) : var.associated_security_group_ids
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  dynamic "kubernetes_network_config" {
    for_each = compact([var.service_ipv4_cidr])
    content {
      service_ipv4_cidr = kubernetes_network_config.value
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy,
    aws_iam_role_policy_attachment.amazon_eks_service_policy,
    aws_security_group.default,
    aws_security_group_rule.egress,
    aws_security_group_rule.ingress_cidr_blocks,
    aws_security_group_rule.ingress_security_groups,
    aws_security_group_rule.ingress_workers,
    aws_cloudwatch_log_group.default
  ]
}

# Enabling IAM Roles for Service Accounts in Kubernetes cluster
#
# From official docs:
# The IAM roles for service accounts feature is available on new Amazon EKS Kubernetes version 1.14 clusters,
# and clusters that were updated to versions 1.14 or 1.13 on or after September 3rd, 2019.
#
# https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
# https://medium.com/@marcincuber/amazon-eks-with-oidc-provider-iam-roles-for-kubernetes-services-accounts-59015d15cb0c
#

data "tls_certificate" "cluster" {
  count = local.enabled && var.oidc_provider_enabled ? 1 : 0
  url   = join("", aws_eks_cluster.default.*.identity.0.oidc.0.issuer)
}

resource "aws_iam_openid_connect_provider" "default" {
  count = local.enabled && var.oidc_provider_enabled ? 1 : 0
  url   = join("", aws_eks_cluster.default.*.identity.0.oidc.0.issuer)
  tags  = module.label.tags

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [join("", data.tls_certificate.cluster.*.certificates.0.sha1_fingerprint)]
}

resource "aws_eks_addon" "cluster" {
  for_each = local.enabled ? {
    for addon in var.addons :
    addon.addon_name => addon
  } : {}

  cluster_name             = join("", aws_eks_cluster.default.*.name)
  addon_name               = each.key
  addon_version            = lookup(each.value, "addon_version", null)
  resolve_conflicts        = lookup(each.value, "resolve_conflicts", null)
  service_account_role_arn = lookup(each.value, "service_account_role_arn", null)

  tags = module.label.tags
}
