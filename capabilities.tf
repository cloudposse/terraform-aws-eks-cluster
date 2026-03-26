# EKS Capabilities: Argo CD, ACK, KRO
# https://docs.aws.amazon.com/eks/latest/userguide/capabilities.html

locals {
  enabled_capabilities = {
    for k, v in var.capabilities : k => v if local.enabled && v.enabled
  }

  # Capabilities that need auto-created IAM roles
  capabilities_needing_roles = {
    for k, v in local.enabled_capabilities : k => v if v.role_arn == null
  }

  # Final role ARN map: auto-created or user-provided
  capability_role_arns = {
    for k, v in local.enabled_capabilities : k => coalesce(
      v.role_arn,
      try(aws_iam_role.capability[k].arn, null)
    )
  }
}

# IAM roles for capabilities that don't provide their own
module "capability_label" {
  for_each = local.capabilities_needing_roles

  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["capability", each.key]
  context    = module.this.context
}

data "aws_iam_policy_document" "capability_assume_role" {
  count = length(local.capabilities_needing_roles) > 0 ? 1 : 0

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
  for_each = local.capabilities_needing_roles

  name                 = module.capability_label[each.key].id
  assume_role_policy   = one(data.aws_iam_policy_document.capability_assume_role[*].json)
  tags                 = module.capability_label[each.key].tags
  permissions_boundary = var.permissions_boundary
}

resource "aws_eks_capability" "default" {
  for_each = local.enabled_capabilities

  cluster_name              = local.eks_cluster_id
  capability_name           = each.key
  type                      = each.value.type
  role_arn                  = local.capability_role_arns[each.key]
  delete_propagation_policy = each.value.delete_propagation_policy
  tags                      = module.label.tags

  dynamic "configuration" {
    for_each = each.value.configuration != null && each.value.type == "ARGOCD" ? [each.value.configuration] : []
    content {
      dynamic "argo_cd" {
        for_each = configuration.value.argo_cd != null ? [configuration.value.argo_cd] : []
        content {
          namespace = argo_cd.value.namespace

          dynamic "aws_idc" {
            for_each = argo_cd.value.aws_idc != null ? [argo_cd.value.aws_idc] : []
            content {
              idc_instance_arn = aws_idc.value.idc_instance_arn
              idc_region       = aws_idc.value.idc_region
            }
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
    create = each.value.create_timeout
    update = each.value.update_timeout
    delete = each.value.delete_timeout
  }

  depends_on = [
    aws_eks_cluster.default,
    aws_iam_role.capability,
  ]
}
