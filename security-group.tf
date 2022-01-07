locals {
  rule_matrix = [
    {
      key                       = "ingress-allowed-security-groups"
      source_security_group_ids = local.allowed_security_group_ids
      rules = [{
        key         = "ingress-allowed-security-groups"
        type        = "ingress"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        description = "Allow all inbound traffic from existing Security Groups"
      }]
    },
    {
      key         = "ingress-cidr-blocks"
      cidr_blocks = var.allowed_cidr_blocks
      rules = [{
        key         = "ingress-cidr-blocks"
        type        = "ingress"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        description = "Allow all inbound traffic from CIDR blocks"
      }]
    },
    {
      key                       = "ingress-workers"
      source_security_group_ids = var.workers_security_group_ids
      rules = [{
        key         = "ingress-workers"
        type        = "ingress"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        description = "Allow all inbound traffic from EKS workers Security Group"
      }]
    }
  ]
}

# If `var.create_security_group=true`, `module "aws_security_group"` will create a new Security Group and apply all the rules to it
# Used with unmanaged worker nodes
module "aws_security_group" {
  source  = "cloudposse/security-group/aws"
  version = "0.4.3"

  enabled = local.enabled && var.create_security_group

  security_group_name        = length(var.security_group_name) > 0 ? var.security_group_name : [module.label.id]
  security_group_description = var.security_group_description
  allow_all_egress           = true

  rules       = var.additional_security_group_rules
  rule_matrix = local.rule_matrix

  vpc_id = var.vpc_id

  create_before_destroy         = var.security_group_create_before_destroy
  security_group_create_timeout = var.security_group_create_timeout
  security_group_delete_timeout = var.security_group_delete_timeout

  context = module.label.context
}

# If `var.create_security_group=false`, add rules to the EKS cluster managed Security Group
# Used with managed Node Groups
resource "aws_security_group_rule" "ingress_security_groups" {
  count                    = local.enabled && var.create_security_group == false ? length(var.allowed_security_group_ids) : 0
  description              = "Allow inbound traffic from existing Security Groups"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = join("", aws_eks_cluster.default.*.vpc_config.0.cluster_security_group_id)
  type                     = "ingress"
}

resource "aws_security_group_rule" "ingress_cidr_blocks" {
  count             = local.enabled && var.create_security_group == false && length(var.allowed_cidr_blocks) > 0 ? 1 : 0
  description       = "Allow inbound traffic from CIDR blocks"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = join("", aws_eks_cluster.default.*.vpc_config.0.cluster_security_group_id)
  type              = "ingress"
}
