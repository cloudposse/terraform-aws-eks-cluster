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

variable "kubernetes_version" {
  type        = string
  default     = ""
  description = "Desired Kubernetes master version. If you do not specify a value, the latest available version is used"
}

variable "health_check_type" {
  type        = "string"
  description = "Controls how health checking is done. Valid values are `EC2` or `ELB`"
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Associate a public IP address with an instance in a VPC"
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

variable "map_additional_aws_accounts" {
  description = "Additional AWS account numbers to add to `config-map-aws-auth` ConfigMap"
  type        = list(string)
  default     = []
}

variable "map_additional_iam_roles" {
  description = "Additional IAM roles to add to `config-map-aws-auth` ConfigMap"

  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  default = []
}

variable "map_additional_iam_users" {
  description = "Additional IAM users to add to `config-map-aws-auth` ConfigMap"

  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = []
}

variable "kubeconfig_path" {
  type        = string
  description = "The path to `kubeconfig` file"
}

variable "configmap_auth_template_file" {
  type        = string
  default     = ""
  description = "Path to `config_auth_template_file`"
}

variable "configmap_auth_file" {
  type        = string
  default     = ""
  description = "Path to `configmap_auth_file`"
}

variable "install_aws_cli" {
  type        = bool
  default     = false
  description = "Set to `true` to install AWS CLI if the module is provisioned on workstations where AWS CLI is not installed by default, e.g. Terraform Cloud workers"
}

variable "install_kubectl" {
  type        = bool
  default     = false
  description = "Set to `true` to install `kubectl` if the module is provisioned on workstations where `kubectl` is not installed by default, e.g. Terraform Cloud workers"
}

variable "kubectl_version" {
  type        = string
  default     = ""
  description = "`kubectl` version to install. If not specified, the latest version will be used"
}

variable "external_packages_install_path" {
  type        = string
  default     = ""
  description = "Path to install external packages, e.g. AWS CLI and `kubectl`. Used when the module is provisioned on workstations where the external packages are not installed by default, e.g. Terraform Cloud workers"
}

variable "aws_eks_update_kubeconfig_additional_arguments" {
  type        = string
  default     = ""
  description = "Additional arguments for `aws eks update-kubeconfig` command, e.g. `--role-arn xxxxxxxxx`. For more info, see https://docs.aws.amazon.com/cli/latest/reference/eks/update-kubeconfig.html"
}

variable "aws_cli_assume_role_arn" {
  type        = string
  default     = ""
  description = "IAM Role ARN for AWS CLI to assume before calling `aws eks` to update kubeconfig"
}

variable "aws_cli_assume_role_session_name" {
  type        = string
  default     = ""
  description = "An identifier for the assumed role session when assuming the IAM Role for AWS CLI before calling `aws eks` to update `kubeconfig`"
}
