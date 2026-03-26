# EKS Capabilities: Argo CD, ACK, KRO
# https://docs.aws.amazon.com/eks/latest/userguide/capabilities.html

locals {
  # Use toset of keys to ensure for_each keys are always known at plan time.
  # The map keys come from var.capabilities which is a static configuration.
  enabled_capability_keys = toset([
    for k, v in var.capabilities : k if local.enabled && v.enabled
  ])

  # Keys of capabilities that need auto-created IAM roles.
  # Uses create_iam_role (a static bool) instead of role_arn == null
  # to ensure for_each keys are always known at plan time.
  capability_keys_needing_roles = toset([
    for k, v in var.capabilities : k if local.enabled && v.enabled && v.create_iam_role
  ])

  # Final role ARN map: auto-created or user-provided
  capability_role_arns = {
    for k in local.enabled_capability_keys : k => (
      var.capabilities[k].create_iam_role ? aws_iam_role.capability[k].arn : var.capabilities[k].role_arn
    )
  }
}

# IAM roles for capabilities that don't provide their own
module "capability_label" {
  for_each = local.capability_keys_needing_roles

  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["capability", each.key]
  context    = module.this.context
}

data "aws_iam_policy_document" "capability_assume_role" {
  count = length(local.capability_keys_needing_roles) > 0 ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["capabilities.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "capability" {
  for_each = local.capability_keys_needing_roles

  name                 = module.capability_label[each.key].id
  assume_role_policy   = one(data.aws_iam_policy_document.capability_assume_role[*].json)
  tags                 = module.capability_label[each.key].tags
  permissions_boundary = var.permissions_boundary
}

resource "aws_eks_capability" "default" {
  for_each = local.enabled_capability_keys

  cluster_name              = local.eks_cluster_id
  capability_name           = each.value
  type                      = var.capabilities[each.value].type
  role_arn                  = local.capability_role_arns[each.value]
  delete_propagation_policy = var.capabilities[each.value].delete_propagation_policy
  tags                      = module.label.tags

  dynamic "configuration" {
    # The AWS API requires configuration with argo_cd and aws_idc for ARGOCD capabilities.
    # Skip the entire configuration block if aws_idc is not provided -- the capability
    # cannot be created without it. Provide aws_idc in your stack config to enable.
    for_each = (
      var.capabilities[each.value].type == "ARGOCD" &&
      var.capabilities[each.value].configuration != null &&
      try(var.capabilities[each.value].configuration.argo_cd.aws_idc, null) != null
    ) ? [var.capabilities[each.value].configuration] : []
    content {
      dynamic "argo_cd" {
        for_each = configuration.value.argo_cd != null ? [configuration.value.argo_cd] : []
        content {
          namespace = argo_cd.value.namespace

          aws_idc {
            idc_instance_arn = argo_cd.value.aws_idc.idc_instance_arn
            idc_region       = argo_cd.value.aws_idc.idc_region
          }

          dynamic "network_access" {
            for_each = argo_cd.value.network_access != null ? [argo_cd.value.network_access] : []
            content {
              vpce_ids = network_access.value.vpce_ids
            }
          }

          dynamic "rbac_role_mapping" {
            for_each = argo_cd.value.rbac_role_mapping
            content {
              role = rbac_role_mapping.value.role

              dynamic "identity" {
                for_each = rbac_role_mapping.value.identity
                content {
                  id   = identity.value.id
                  type = identity.value.type
                }
              }
            }
          }
        }
      }
    }
  }

  timeouts {
    create = var.capabilities[each.value].create_timeout
    update = var.capabilities[each.value].update_timeout
    delete = var.capabilities[each.value].delete_timeout
  }

  depends_on = [
    aws_eks_cluster.default,
    aws_iam_role.capability,
  ]
}
