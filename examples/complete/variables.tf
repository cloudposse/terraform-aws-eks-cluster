variable "namespace" {
  type        = "string"
  default     = "eg"
  description = "Namespace, which could be your organization name, e.g. 'eg' or 'cp'"
}

variable "stage" {
  type        = "string"
  default     = "testing"
  description = "Stage, e.g. 'prod', 'staging', 'dev', or 'testing'"
}

variable "environment" {
  type        = "string"
  default     = ""
  description = "Environment, e.g. 'testing', 'UAT'"
}

variable "name" {
  type        = "string"
  default     = "cluster"
  description = "Solution name, e.g. 'app' or 'cluster'"
}

variable "delimiter" {
  type        = "string"
  default     = "-"
  description = "Delimiter to be used between `name`, `namespace`, `stage`, etc."
}

variable "attributes" {
  type        = "list"
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
}

variable "enabled" {
  type        = "string"
  description = "Whether to create the resources. Set to `false` to prevent the module from creating any resources"
  default     = "true"
}

variable "allowed_security_groups" {
  type        = "list"
  default     = []
  description = "List of Security Group IDs to be allowed to connect to the EKS cluster"
}

variable "allowed_cidr_blocks" {
  type        = "list"
  default     = []
  description = "List of CIDR blocks to be allowed to connect to the EKS cluster"
}

variable "region" {
  type        = "string"
  default     = "us-west-2"
  description = "AWS Region"
}

variable "image_id" {
  type        = "string"
  description = "EC2 image ID to launch. If not provided, the module will lookup the most recent EKS AMI. See https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html for more details on EKS-optimized images"
  default     = ""
}

variable "eks_worker_ami_name_filter" {
  type        = "string"
  description = "AMI name filter to lookup the most recent EKS AMI if `image_id` is not provided"
  default     = "amazon-eks-node-v*"
}

variable "instance_type" {
  type        = "string"
  default     = "t2.medium"
  description = "Instance type to launch"
}

variable "health_check_type" {
  type        = "string"
  description = "Controls how health checking is done. Valid values are `EC2` or `ELB`"
  default     = "EC2"
}

variable "max_size" {
  default     = 3
  description = "The maximum size of the AutoScaling Group"
}

variable "min_size" {
  default     = 1
  description = "The minimum size of the AutoScaling Group"
}

variable "wait_for_capacity_timeout" {
  type        = "string"
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out. (See also Waiting for Capacity below.) Setting this to '0' causes Terraform to skip all Capacity Waiting behavior"
  default     = "10m"
}

variable "associate_public_ip_address" {
  description = "Associate a public IP address with the worker nodes in the VPC"
  default     = true
}

variable "autoscaling_policies_enabled" {
  type        = "string"
  default     = "true"
  description = "Whether to create `aws_autoscaling_policy` and `aws_cloudwatch_metric_alarm` resources to control Auto Scaling"
}

variable "cpu_utilization_high_threshold_percent" {
  type        = "string"
  default     = "80"
  description = "Worker nodes AutoScaling Group CPU utilization high threshold percent"
}

variable "cpu_utilization_low_threshold_percent" {
  type        = "string"
  default     = "20"
  description = "Worker nodes AutoScaling Group CPU utilization low threshold percent"
}
