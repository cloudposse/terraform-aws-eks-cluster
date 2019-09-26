variable "region" {
  type        = string
  description = "AWS Region"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

variable "namespace" {
  type        = string
  description = "Namespace, which could be your organization name, e.g. 'eg' or 'cp'"
}

variable "stage" {
  type        = string
  description = "Stage, e.g. 'prod', 'staging', 'dev' or 'testing'"
}

variable "name" {
  type        = string
  description = "Solution name, e.g. 'app' or 'cluster'"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `name`, `namespace`, `stage`, etc."
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
}

variable "instance_type" {
  type        = string
  description = "Instance type to launch"
}

variable "health_check_type" {
  type        = "string"
  description = "Controls how health checking is done. Valid values are `EC2` or `ELB`"
}

variable "max_size" {
  type        = number
  description = "The maximum size of the AutoScaling Group"
}

variable "min_size" {
  type        = number
  description = "The minimum size of the AutoScaling Group"
}

variable "wait_for_capacity_timeout" {
  type        = string
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out. Setting this to '0' causes Terraform to skip all Capacity Waiting behavior"
}

variable "autoscaling_policies_enabled" {
  type        = bool
  description = "Whether to create `aws_autoscaling_policy` and `aws_cloudwatch_metric_alarm` resources to control Auto Scaling"
}

variable "cpu_utilization_high_threshold_percent" {
  type        = number
  description = "Worker nodes AutoScaling Group CPU utilization high threshold percent"
}

variable "cpu_utilization_low_threshold_percent" {
  type        = number
  description = "Worker nodes AutoScaling Group CPU utilization low threshold percent"
}

variable "cluster_auth_type" {
  type        = string
  description = "Cluster authentication type. Valid values are `aws-eks-get-token` and `aws-iam-authenticator`. Amazon EKS uses the `aws eks get-token` command (available in version 1.16.232 or greater of the AWS CLI) or the AWS IAM Authenticator for Kubernetes with `kubectl` for cluster authentication. For more info, see https://docs.aws.amazon.com/en_pv/eks/latest/userguide/create-kubeconfig.html"
}
