module "aws_security_group" {
  source  = "cloudposse/security-group/aws"
  version = "0.4.3"

  enabled = local.enabled && var.create_security_group

  security_group_name        = length(var.security_group_name) > 0 ? var.security_group_name : [module.label.id]
  security_group_description = var.security_group_description

  allow_all_egress = true

  rules = var.additional_security_group_rules

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

  vpc_id = var.vpc_id

  create_before_destroy         = var.security_group_create_before_destroy
  security_group_create_timeout = var.security_group_create_timeout
  security_group_delete_timeout = var.security_group_delete_timeout

  context = module.label.context
}
