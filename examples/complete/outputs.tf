output "kubeconfig" {
  description = "`kubectl` configuration to connect to the cluster https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#obtaining-kubectl-configuration-from-terraform"
  value       = "${module.eks_cluster.kubeconfig}"
}

output "security_group_id" {
  description = "ID of the EKS cluster Security Group"
  value       = "${module.eks_cluster.security_group_id}"
}

output "security_group_arn" {
  description = "ARN of the EKS cluster Security Group"
  value       = "${module.eks_cluster.security_group_arn}"
}

output "security_group_name" {
  description = "Name of the EKS cluster Security Group"
  value       = "${module.eks_cluster.security_group_name}"
}

output "eks_cluster_id" {
  description = "The name of the cluster"
  value       = "${module.eks_cluster.eks_cluster_id}"
}

output "eks_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = "${module.eks_cluster.eks_cluster_arn}"
}

output "eks_cluster_certificate_authority_date" {
  description = "The base64 encoded certificate data required to communicate with the cluster"
  value       = "${module.eks_cluster.eks_cluster_certificate_authority_date}"
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = "${module.eks_cluster.eks_cluster_endpoint}"
}

output "eks_cluster_version" {
  description = "The Kubernetes server version of the cluster"
  value       = "${module.eks_cluster.eks_cluster_version}"
}
