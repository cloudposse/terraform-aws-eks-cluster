locals {
  cluster_name = "${var.namespace}-${var.stage}-${var.name}-cluster"
  set_context = "aws eks --region=${var.region} update-kubeconfig --name=${local.cluster_name}"
}

module "eks_cluster" {
  source     = "git::https://github.com/instructure/terraform-aws-eks-cluster.git?ref=master"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  tags       = var.tags
  vpc_id     = var.vpc_id
  subnet_ids = var.subnets

  # `workers_security_group_count` is needed to prevent `count can't be computed` errors
  workers_security_group_ids   = ["${module.eks_workers.security_group_id}"]
  workers_security_group_count = 1
}

module "eks_workers" {
  source = "git::https://github.com/instructure/terraform-aws-eks-workers.git?ref=inst-version"

  namespace     = var.namespace
  stage         = var.stage
  name          = var.name
  tags          = var.tags
  instance_type = var.instance_type
  vpc_id        = var.vpc_id
  subnet_ids    = var.subnets
  key_name                           = var.ssh_key
  health_check_type                  = "EC2"
  min_size                           = 2
  max_size                           = 3
  wait_for_capacity_timeout          = "10m"
  associate_public_ip_address        = true
  cluster_name                       = local.cluster_name
  cluster_endpoint                   = "${module.eks_cluster.eks_cluster_endpoint}"
  cluster_certificate_authority_data = "${module.eks_cluster.eks_cluster_certificate_authority_data}"
  cluster_security_group_id          = "${module.eks_cluster.security_group_id}"

  # Auto-scaling policies and CloudWatch metric alarms
  autoscaling_policies_enabled           = "true"
  cpu_utilization_high_threshold_percent = "80"
  cpu_utilization_low_threshold_percent  = "20"
}
