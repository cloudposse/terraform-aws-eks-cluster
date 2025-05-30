locals {
  create_eks_service_role = local.enabled && var.create_eks_service_role
  create_node_role        = local.enabled && var.create_node_role

  eks_service_role_arn = local.create_eks_service_role ? one(aws_iam_role.default[*].arn) : var.eks_cluster_service_role_arn
  node_role_arn        = local.create_node_role ? one(aws_iam_role.node[*].arn) : var.node_role_arn

  auto_mode_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSComputePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
  ]
}

data "aws_iam_policy_document" "assume_role" {
  count = local.create_eks_service_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = concat(["sts:AssumeRole"], var.cluster_auto_mode_enabled ? ["sts:TagSession"] : [])

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "default" {
  count = local.create_eks_service_role ? 1 : 0

  name                 = module.label.id
  assume_role_policy   = one(data.aws_iam_policy_document.assume_role[*].json)
  tags                 = module.label.tags
  permissions_boundary = var.permissions_boundary
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  count = local.create_eks_service_role ? 1 : 0

  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKSClusterPolicy", one(data.aws_partition.current[*].partition))
  role       = one(aws_iam_role.default[*].name)
}

resource "aws_iam_role_policy_attachment" "amazon_eks_service_policy" {
  count = local.create_eks_service_role ? 1 : 0

  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKSServicePolicy", one(data.aws_partition.current[*].partition))
  role       = one(aws_iam_role.default[*].name)
}


# AmazonEKSClusterPolicy managed policy doesn't contain all necessary permissions to create
# ELB service-linked role required during LB provisioning by Kubernetes.
# Because of that, on a new AWS account (where load balancers have not been provisioned yet, `nginx-ingress` fails to provision a load balancer

data "aws_iam_policy_document" "cluster_elb_service_role" {
  count = local.create_eks_service_role ? 1 : 0

  statement {
    sid    = "AllowElasticLoadBalancer"
    effect = "Allow"
    #bridgecrew:skip=BC_AWS_IAM_57:There is no workable constraint to add to this policy
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInternetGateways",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSubnets"
    ]
    resources = ["*"]
  }
  # Adding a policy to cluster IAM role that deny permissions to logs:CreateLogGroup
  # it is not needed since we create the log group elsewhere in this module, and it is causing trouble during "destroy"
  statement {
    sid    = "DenyCreateLogGroup"
    effect = "Deny"
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cluster_elb_service_role" {
  count = local.create_eks_service_role ? 1 : 0

  name   = "${module.label.id}-ServiceRole"
  policy = one(data.aws_iam_policy_document.cluster_elb_service_role[*].json)

  tags = module.this.tags
}

resource "aws_iam_role_policy_attachment" "cluster_elb_service_role" {
  count = local.create_eks_service_role ? 1 : 0

  policy_arn = one(aws_iam_policy.cluster_elb_service_role[*].arn)
  role       = one(aws_iam_role.default[*].name)
}

resource "aws_iam_role_policy_attachment" "auto_mode_policies" {
  count      = var.cluster_auto_mode_enabled && local.create_eks_service_role ? length(local.auto_mode_policies) : 0
  policy_arn = element(local.auto_mode_policies, count.index)
  role       = one(aws_iam_role.default[*].name)
}

data "aws_iam_policy_document" "node_assume_role" {
  count = local.create_node_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  count = local.create_node_role ? 1 : 0

  name                 = "${module.label.id}-node"
  assume_role_policy   = one(data.aws_iam_policy_document.node_assume_role[*].json)
  tags                 = module.label.tags
  permissions_boundary = var.permissions_boundary
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  count = local.create_node_role ? 1 : 0

  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKSWorkerNodePolicy", one(data.aws_partition.current[*].partition))
  role       = one(aws_iam_role.node[*].name)
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  count = local.create_node_role ? 1 : 0

  policy_arn = format("arn:%s:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", one(data.aws_partition.current[*].partition))
  role       = one(aws_iam_role.node[*].name)
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  count = local.create_node_role ? 1 : 0

  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKS_CNI_Policy", one(data.aws_partition.current[*].partition))
  role       = one(aws_iam_role.node[*].name)
}
