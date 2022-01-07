locals {
  allowed_security_group_rule = local.enabled && length(local.allowed_security_group_ids) > 0 ? {
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
  } : null

  allowed_cidr_blocks_rule = local.enabled && length(var.allowed_cidr_blocks) > 0 ? {
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
  } : null

  workers_security_group_rule = local.enabled && length(var.workers_security_group_ids) > 0 ? {
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
  } : null

  rule_matrix = compact([
    local.allowed_security_group_rule,
    local.allowed_cidr_blocks_rule,
    local.workers_security_group_rule
  ])
}

module "aws_security_group" {
  source  = "cloudposse/security-group/aws"
  version = "0.4.3"

  security_group_name        = length(var.security_group_name) > 0 ? var.security_group_name : [module.label.id]
  security_group_description = var.security_group_description
  allow_all_egress           = true

  rules       = var.additional_security_group_rules
  rule_matrix = local.rule_matrix

  # If `var.create_security_group=true`, `module "aws_security_group"` will create a new Security Group and apply all the rules to it - use this with unmanaged worker nodes
  # If `var.create_security_group=false`, `module "aws_security_group"` will use the EKS cluster managed Security Group and apply all the rules to it - use this with managed Node Groups
  target_security_group_id = var.create_security_group ? [] : [join("", aws_eks_cluster.default.*.vpc_config.0.cluster_security_group_id)]

  vpc_id = var.vpc_id

  create_before_destroy         = var.security_group_create_before_destroy
  security_group_create_timeout = var.security_group_create_timeout
  security_group_delete_timeout = var.security_group_delete_timeout

  context = module.label.context
}
