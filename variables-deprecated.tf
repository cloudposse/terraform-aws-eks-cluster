variable "allowed_security_groups" {
  type        = list(string)
  default     = []
  description = <<-EOT
    DEPRECATED: Use `allowed_security_group_ids` instead.
    Historical description: List of Security Group IDs to be allowed to connect to the EKS cluster.
    Historical default: `[]`
    EOT
}
