output "kubeconfig" {
  description = "`kubeconfig` configuration to connect to the cluster using `kubectl`. https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#configuring-kubectl-for-eks"
  value       = join("", data.template_file.kubeconfig.*.rendered)
}

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

output "eks_cluster_certificate_authority_data" {
  description = "The base64 encoded certificate data required to communicate with the cluster"
  value       = local.certificate_authority_data
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = join("", aws_eks_cluster.default.*.endpoint)
}

output "eks_cluster_version" {
  description = "The Kubernetes server version of the cluster"
  value       = join("", aws_eks_cluster.default.*.version)
}
