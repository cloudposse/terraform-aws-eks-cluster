# security-group-inputs Version: 2
#

locals {
  allowed_security_group_ids = concat(var.allowed_security_groups, var.allowed_security_group_ids, var.workers_security_group_ids)
}

variable "create_security_group" {
  type        = bool
  default     = false
  description = <<-EOT
    Set to `true` to create and configure an additional Security Group for the cluster.
    Only for backwards compatibility, if you are updating this module to the latest version on existing clusters, not recommended for new clusters.
    EKS creates a managed Security Group for the cluster automatically, places the control plane and managed nodes into the Security Group,
    and you can also allow unmanaged nodes to communicate with the cluster by using the `allowed_security_group_ids` variable.
    The additional Security Group is kept in the module for backwards compatibility and will be removed in future releases along with this variable.
    See https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html for more details.
    EOT
}

variable "associated_security_group_ids" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of IDs of Security Groups to associate the cluster with.
    These security groups will not be modified.
    EOT
}

variable "allowed_security_group_ids" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of IDs of Security Groups to allow access to the cluster.
    EOT
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of IPv4 CIDRs to allow access to the cluster.
    The length of this list must be known at "plan" time.
    EOT
}

variable "custom_ingress_rules" {
  type = list(object({
    description              = string
    from_port                = number
    to_port                  = number
    protocol                 = string
    source_security_group_id = string
  }))
  default     = []
  description = <<-EOT
    A List of Objects, which are custom security group rules that
    EOT
}
