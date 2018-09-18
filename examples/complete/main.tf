provider "aws" {
  region = "${var.region}"
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=master"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
  cidr_block = "10.0.0.0/16"
}

module "subnets" {
  source              = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=master"
  availability_zones  = ["${data.aws_availability_zones.available.names}"]
  namespace           = "${var.namespace}"
  stage               = "${var.stage}"
  name                = "${var.name}"
  attributes          = "${var.attributes}"
  tags                = "${var.tags}"
  region              = "${var.region}"
  vpc_id              = "${module.vpc.vpc_id}"
  igw_id              = "${module.vpc.igw_id}"
  cidr_block          = "${module.vpc.vpc_cidr_block}"
  nat_gateway_enabled = "true"
}

module "eks_cluster" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-eks-cluster.git?ref=master"
  namespace               = "${var.namespace}"
  stage                   = "${var.stage}"
  name                    = "${var.name}"
  attributes              = "${var.attributes}"
  tags                    = "${var.tags}"
  vpc_id                  = "${module.vpc.vpc_id}"
  subnet_ids              = ["${module.subnets.public_subnet_ids}"]
  allowed_security_groups = ["${var.allowed_security_groups}"]
  allowed_cidr_blocks     = ["${var.allowed_cidr_blocks}"]
}
