output "security_group_id" {
  description = "ID of the EKS cluster Security Group"
  value       = join("", aws_security_group.default.*.id)
}

output "security_group_arn" {
  description = "ARN of the EKS cluster Security Group"
  value       = join("", aws_security_group.default.*.arn)
}

output "security_group_name" {
  description = "Name of the EKS cluster Security Group"
  value       = join("", aws_security_group.default.*.name)
}

output "eks_cluster_id" {
  description = "The name of the cluster"
  value       = join("", aws_eks_cluster.default.*.id)
}

output "eks_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = join("", aws_eks_cluster.default.*.arn)
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = join("", aws_eks_cluster.default.*.endpoint)
}

output "eks_cluster_version" {
  description = "The Kubernetes server version of the cluster"
  value       = join("", aws_eks_cluster.default.*.version)
}

output "eks_cluster_identity_oidc_issuer" {
  description = "The OIDC Identity issuer for the cluster"
  value       = join("", aws_eks_cluster.default.*.identity.0.oidc.0.issuer)
}

output "eks_cluster_identity_oidc_issuer_arn" {
  description = "The OIDC Identity issuer ARN for the cluster that can be used to associate IAM roles with a service account"
  value       = join("", aws_iam_openid_connect_provider.default.*.arn)
}

output "eks_cluster_certificate_authority_data" {
  description = "The Kubernetes cluster certificate authority data"
  value       = local.certificate_authority_data
}

output "eks_cluster_managed_security_group_id" {
  description = "Security Group ID that was created by EKS for the cluster. EKS creates a Security Group and applies it to ENI that is attached to EKS Control Plane master nodes and to any managed workloads"
  value       = join("", aws_eks_cluster.default.*.vpc_config.0.cluster_security_group_id)
}

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = join("", aws_iam_role.default.*.arn)
}

output "kubernetes_config_map_id" {
  description = "ID of `aws-auth` Kubernetes ConfigMap"
  value       = var.kubernetes_config_map_ignore_role_changes ? join("", kubernetes_config_map.aws_auth_ignore_changes.*.id) : join("", kubernetes_config_map.aws_auth.*.id)
}

output "enable_cluster_encryption_config" {
  description = "If true, Cluster Encryption Configuration is enabled"
  value       = var.enable_cluster_encryption_config
}

output "cluster_encryption_config_resources" {
  description = "Cluster Encryption Config Resources"
  value       = var.cluster_encryption_config_resources
}

output "cluster_encryption_config_provider_key_arn" {
  description = "Cluster Encryption Config KMS Key ARN"
  value       = local.cluster_encryption_config.provider_key_arn
}

output "cluster_encryption_config_provider_key_alias" {
  description = "Cluster Encryption Config KMS Key Alias ARN"
  value       = join("", aws_kms_alias.cluster.*.arn)
}
