variable "region" {
  type        = string
  description = "AWS Region"
}

variable "namespace" {
  type        = string
  description = "Namespace, which could be your organization name, e.g. 'eg' or 'cp'"
  default     = ""
}

variable "stage" {
  type        = string
  description = "Stage, e.g. 'prod', 'staging', 'dev', or 'test'"
  default     = ""
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

variable "enabled" {
  type        = bool
  description = "Whether to create the resources. Set to `false` to prevent the module from creating any resources"
  default     = true
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the EKS cluster"
}

variable "subnet_ids" {
  description = "A list of subnet IDs to launch the cluster in"
  type        = list(string)
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Associate a public IP address with an instance in a VPC"
  default     = true
}

variable "allowed_security_groups" {
  type        = list(string)
  default     = []
  description = "List of Security Group IDs to be allowed to connect to the EKS cluster"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = []
  description = "List of CIDR blocks to be allowed to connect to the EKS cluster"
}

variable "workers_role_arns" {
  type        = list(string)
  description = "List of Role ARNs of the worker nodes"
}

variable "workers_security_group_ids" {
  type        = list(string)
  description = "Security Group IDs of the worker nodes"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.14"
  description = "Desired Kubernetes master version. If you do not specify a value, the latest available version is used"
}

variable "oidc_provider_enabled" {
  type        = bool
  default     = false
  description = "Create an IAM OIDC identity provider for the cluster, then you can create IAM roles to associate with a service account in the cluster, instead of using kiam or kube2iam. For more information, see https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html"
}

variable "endpoint_private_access" {
  type        = bool
  default     = false
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled. Default to AWS EKS resource and it is false"
}

variable "endpoint_public_access" {
  type        = bool
  default     = true
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled. Default to AWS EKS resource and it is true"
}

variable "enabled_cluster_log_types" {
  type        = list(string)
  default     = []
  description = "A list of the desired control plane logging to enable. For more information, see https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. Possible values [`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`]"
}

variable "apply_config_map_aws_auth" {
  type        = bool
  default     = true
  description = "Whether to generate local files from `kubeconfig` and `config-map-aws-auth` templates and perform `kubectl apply` to apply the ConfigMap to allow worker nodes to join the EKS cluster"
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
  default     = "~/.kube/config"
  description = "The path to `kubeconfig` file"
}

variable "local_exec_interpreter" {
  type        = string
  default     = "/bin/bash"
  description = "shell to use for local exec"
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
  description = "IAM Role ARN for AWS CLI to assume before calling `aws eks` to update `kubeconfig`"
}

variable "aws_cli_assume_role_session_name" {
  type        = string
  default     = ""
  description = "An identifier for the assumed role session when assuming the IAM Role for AWS CLI before calling `aws eks` to update `kubeconfig`"
}

variable "jq_version" {
  type        = string
  default     = "1.6"
  description = "Version of `jq` to download to extract temporaly credentials after running `aws sts assume-role` if AWS CLI needs to assume role to access the cluster (if variable `aws_cli_assume_role_arn` is set)"
}
