locals {
  create_eks_service_role = local.enabled && var.create_eks_service_role

  eks_service_role_arn = local.create_eks_service_role ? join("", aws_iam_role.default.*.arn) : var.eks_cluster_service_role_arn
}

data "aws_iam_policy_document" "assume_role" {
  count = local.create_eks_service_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "default" {
  count = local.create_eks_service_role ? 1 : 0

  name                 = module.label.id
  assume_role_policy   = join("", data.aws_iam_policy_document.assume_role.*.json)
  tags                 = module.label.tags
  permissions_boundary = var.permissions_boundary
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  count = local.create_eks_service_role ? 1 : 0

  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKSClusterPolicy", join("", data.aws_partition.current.*.partition))
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_iam_role_policy_attachment" "amazon_eks_service_policy" {
  count = local.create_eks_service_role ? 1 : 0

  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKSServicePolicy", join("", data.aws_partition.current.*.partition))
  role       = join("", aws_iam_role.default.*.name)
}

# AmazonEKSClusterPolicy managed policy doesn't contain all necessary permissions to create
# ELB service-linked role required during LB provisioning by Kubernetes.
# Because of that, on a new AWS account (where load balancers have not been provisioned yet, `nginx-ingress` fails to provision a load balancer

data "aws_iam_policy_document" "cluster_elb_service_role" {
  count = local.create_eks_service_role ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInternetGateways",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSubnets"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cluster_elb_service_role" {
  count = local.create_eks_service_role ? 1 : 0

  name   = module.label.id
  role   = join("", aws_iam_role.default.*.name)
  policy = join("", data.aws_iam_policy_document.cluster_elb_service_role.*.json)
}

# Adding a policy to cluster IAM role that deny permissions to logs:CreateLogGroup
# it is not needed since we create the log group ourselve in this module, and it is causing trouble during cleanup/deletion

data "aws_iam_policy_document" "cluster_deny_log_group" {
  count = local.create_eks_service_role ? 1 : 0

  statement {
    effect = "Deny"
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cluster_deny_log_group" {
  count = local.create_eks_service_role ? 1 : 0

  name   = module.label.id
  role   = join("", aws_iam_role.default.*.name)
  policy = join("", data.aws_iam_policy_document.cluster_deny_log_group.*.json)
}
