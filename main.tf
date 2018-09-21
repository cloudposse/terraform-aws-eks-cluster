module "label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.5.3"
  namespace   = "${var.namespace}"
  name        = "${var.name}"
  stage       = "${var.stage}"
  environment = "${var.environment}"
  delimiter   = "${var.delimiter}"
  attributes  = "${var.attributes}"
  tags        = "${var.tags}"
  enabled     = "${var.enabled}"
}

data "aws_iam_policy_document" "assume_role" {
  count = "${var.enabled == "true" ? 1 : 0}"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals = {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "default" {
  count              = "${var.enabled == "true" ? 1 : 0}"
  name               = "${module.label.id}"
  assume_role_policy = "${join("", data.aws_iam_policy_document.assume_role.*.json)}"
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  count      = "${var.enabled == "true" ? 1 : 0}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.default.name}"
}

resource "aws_iam_role_policy_attachment" "amazon_eks_service_policy" {
  count      = "${var.enabled == "true" ? 1 : 0}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${join("", aws_iam_role.default.*.name)}"
}

resource "aws_security_group" "default" {
  count       = "${var.enabled == "true" ? 1 : 0}"
  name        = "${module.label.id}"
  description = "Security Group for EKS cluster"
  vpc_id      = "${var.vpc_id}"
  tags        = "${module.label.tags}"
}

resource "aws_security_group_rule" "egress" {
  count             = "${var.enabled == "true" ? 1 : 0}"
  description       = "Allow all egress traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${join("", aws_security_group.default.*.id)}"
  type              = "egress"
}

resource "aws_security_group_rule" "ingress_security_groups" {
  count                    = "${var.enabled == "true" ? length(var.allowed_security_groups) : 0}"
  description              = "Allow inbound traffic from existing Security Groups"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${element(var.allowed_security_groups, count.index)}"
  security_group_id        = "${join("", aws_security_group.default.*.id)}"
  type                     = "ingress"
}

resource "aws_security_group_rule" "ingress_cidr_blocks" {
  count             = "${var.enabled == "true" && length(var.allowed_cidr_blocks) > 0 ? 1 : 0}"
  description       = "Allow inbound traffic from CIDR blocks"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${var.allowed_cidr_blocks}"]
  security_group_id = "${join("", aws_security_group.default.*.id)}"
  type              = "ingress"
}

resource "aws_eks_cluster" "default" {
  count    = "${var.enabled == "true" ? 1 : 0}"
  name     = "${module.label.id}"
  role_arn = "${join("", aws_iam_role.default.*.arn)}"

  vpc_config {
    security_group_ids = ["${join("", aws_security_group.default.*.id)}"]
    subnet_ids         = ["${var.subnet_ids}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.amazon_eks_cluster_policy",
    "aws_iam_role_policy_attachment.amazon_eks_service_policy",
  ]
}

data "template_file" "kubeconfig" {
  count    = "${var.enabled == "true" ? 1 : 0}"
  template = "${file("${path.module}/kubeconfig.tpl")}"

  vars {
    server                     = "${join("", aws_eks_cluster.default.*.endpoint)}"
    certificate_authority_data = "${join("", aws_eks_cluster.default.*.certificate_authority.0.data)}"
    cluster_name               = "${module.label.id}"
  }
}
