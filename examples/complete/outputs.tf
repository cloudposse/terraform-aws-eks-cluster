output "kubeconfig" {
  description = "`kubeconfig` configuration to connect to the cluster using `kubectl`. https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#configuring-kubectl-for-eks"
  value       = "${module.eks_cluster.kubeconfig}"
}

output "config_map_aws_auth" {
  description = "Kubernetes ConfigMap configuration to allow the worker nodes to join the EKS cluster. https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#required-kubernetes-configuration-to-join-worker-nodes"
  value       = "${module.eks_workers.config_map_aws_auth}"
}

output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster Security Group"
  value       = "${module.eks_cluster.security_group_id}"
}

output "eks_cluster_security_group_arn" {
  description = "ARN of the EKS cluster Security Group"
  value       = "${module.eks_cluster.security_group_arn}"
}

output "eks_cluster_security_group_name" {
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

output "eks_cluster_certificate_authority_data" {
  description = "The base64 encoded certificate data required to communicate with the cluster"
  value       = "${module.eks_cluster.eks_cluster_certificate_authority_data}"
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = "${module.eks_cluster.eks_cluster_endpoint}"
}

output "eks_cluster_version" {
  description = "The Kubernetes server version of the cluster"
  value       = "${module.eks_cluster.eks_cluster_version}"
}

output "workers_launch_template_id" {
  description = "ID of the launch template"
  value       = "${module.eks_workers.launch_template_id}"
}

output "workers_launch_template_arn" {
  description = "ARN of the launch template"
  value       = "${module.eks_workers.launch_template_arn}"
}

output "workers_autoscaling_group_id" {
  description = "The AutoScaling Group ID"
  value       = "${module.eks_workers.autoscaling_group_id}"
}

output "workers_autoscaling_group_name" {
  description = "The AutoScaling Group name"
  value       = "${module.eks_workers.autoscaling_group_name}"
}

output "workers_autoscaling_group_arn" {
  description = "ARN of the AutoScaling Group"
  value       = "${module.eks_workers.autoscaling_group_arn}"
}

output "workers_autoscaling_group_min_size" {
  description = "The minimum size of the AutoScaling Group"
  value       = "${module.eks_workers.autoscaling_group_min_size}"
}

output "workers_autoscaling_group_max_size" {
  description = "The maximum size of the AutoScaling Group"
  value       = "${module.eks_workers.autoscaling_group_max_size}"
}

output "workers_autoscaling_group_desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group"
  value       = "${module.eks_workers.autoscaling_group_desired_capacity}"
}

output "workers_autoscaling_group_default_cooldown" {
  description = "Time between a scaling activity and the succeeding scaling activity"
  value       = "${module.eks_workers.autoscaling_group_default_cooldown}"
}

output "workers_autoscaling_group_health_check_grace_period" {
  description = "Time after instance comes into service before checking health"
  value       = "${module.eks_workers.autoscaling_group_health_check_grace_period}"
}

output "workers_autoscaling_group_health_check_type" {
  description = "`EC2` or `ELB`. Controls how health checking is done"
  value       = "${module.eks_workers.autoscaling_group_health_check_type}"
}

output "workers_security_group_id" {
  description = "ID of the worker nodes Security Group"
  value       = "${module.eks_workers.security_group_id}"
}

output "workers_security_group_arn" {
  description = "ARN of the worker nodes Security Group"
  value       = "${module.eks_workers.security_group_arn}"
}

output "workers_security_group_name" {
  description = "Name of the worker nodes Security Group"
  value       = "${module.eks_workers.security_group_name}"
}
