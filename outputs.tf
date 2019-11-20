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
