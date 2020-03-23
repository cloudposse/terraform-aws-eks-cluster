provider "aws" {
  region = var.region
}

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  namespace  = var.namespace
  name       = var.name
  stage      = var.stage
  delimiter  = var.delimiter
  attributes = compact(concat(var.attributes, list("cluster")))
  tags       = var.tags
}

locals {
  # The usage of the specific kubernetes.io/cluster/* resource tags below are required
  # for EKS and Kubernetes to discover and manage networking resources
  # https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#base-vpc-networking
  tags = merge(module.label.tags, map("kubernetes.io/cluster/${module.label.id}", "shared"))

  # Unfortunately, most_recent (https://github.com/cloudposse/terraform-aws-eks-workers/blob/34a43c25624a6efb3ba5d2770a601d7cb3c0d391/main.tf#L141)
  # variable does not work as expected, if you are not going to use custom ami you should
  # enforce usage of eks_worker_ami_name_filter variable to set the right kubernetes version for EKS workers,
  # otherwise will be used the first version of Kubernetes supported by AWS (v1.11) for EKS workers but
  # EKS control plane will use the version specified by kubernetes_version variable.
  eks_worker_ami_name_filter = "amazon-eks-node-${var.kubernetes_version}*"
}

module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.8.1"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  attributes = var.attributes
  cidr_block = "172.16.0.0/16"
  tags       = local.tags
}

module "subnets" {
  source               = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=tags/0.19.0"
  availability_zones   = var.availability_zones
  namespace            = var.namespace
  stage                = var.stage
  name                 = var.name
  attributes           = var.attributes
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = false
  nat_instance_enabled = false
  tags                 = local.tags
}

module "eks_workers" {
  source                             = "git::https://github.com/cloudposse/terraform-aws-eks-workers.git?ref=tags/0.12.0"
  namespace                          = var.namespace
  stage                              = var.stage
  name                               = var.name
  attributes                         = var.attributes
  tags                               = var.tags
  instance_type                      = var.instance_type
  eks_worker_ami_name_filter         = local.eks_worker_ami_name_filter
  vpc_id                             = module.vpc.vpc_id
  subnet_ids                         = module.subnets.public_subnet_ids
  associate_public_ip_address        = var.associate_public_ip_address
  health_check_type                  = var.health_check_type
  min_size                           = var.min_size
  max_size                           = var.max_size
  wait_for_capacity_timeout          = var.wait_for_capacity_timeout
  cluster_name                       = module.label.id
  cluster_endpoint                   = module.eks_cluster.eks_cluster_endpoint
  cluster_certificate_authority_data = module.eks_cluster.eks_cluster_certificate_authority_data
  cluster_security_group_id          = module.eks_cluster.security_group_id

  # Auto-scaling policies and CloudWatch metric alarms
  autoscaling_policies_enabled           = var.autoscaling_policies_enabled
  cpu_utilization_high_threshold_percent = var.cpu_utilization_high_threshold_percent
  cpu_utilization_low_threshold_percent  = var.cpu_utilization_low_threshold_percent
}

module "eks_cluster" {
  source                 = "../../"
  namespace              = var.namespace
  stage                  = var.stage
  name                   = var.name
  attributes             = var.attributes
  tags                   = var.tags
  region                 = var.region
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.subnets.public_subnet_ids
  kubernetes_version     = var.kubernetes_version
  kubeconfig_path        = var.kubeconfig_path
  local_exec_interpreter = var.local_exec_interpreter
  oidc_provider_enabled  = var.oidc_provider_enabled

  install_aws_cli                                = var.install_aws_cli
  install_kubectl                                = var.install_kubectl
  kubectl_version                                = var.kubectl_version
  jq_version                                     = var.jq_version
  external_packages_install_path                 = var.external_packages_install_path
  aws_eks_update_kubeconfig_additional_arguments = var.aws_eks_update_kubeconfig_additional_arguments
  aws_cli_assume_role_arn                        = var.aws_cli_assume_role_arn
  aws_cli_assume_role_session_name               = var.aws_cli_assume_role_session_name

  enabled_cluster_log_types    = var.enabled_cluster_log_types
  cluster_log_retention_period = var.cluster_log_retention_period

  workers_role_arns          = [module.eks_workers.workers_role_arn]
  workers_security_group_ids = [module.eks_workers.security_group_id]
}
