# tflint-ignore: terraform_unused_declarations
variable "region" {
  type        = string
  description = "OBSOLETE (not needed): AWS Region"
  default     = null
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the EKS cluster"
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs to launch the cluster in"
}

variable "cluster_depends_on" {
  type        = any
  description = <<-EOT
    If provided, the EKS will depend on this object, and therefore not be created until this object is finalized.
    This is useful if you want to ensure that the cluster is not created before some other condition is met, e.g. VPNs into the subnet are created.
    EOT
  default     = null
}

variable "create_eks_service_role" {
  type        = bool
  description = "Set `false` to use existing `eks_cluster_service_role_arn` instead of creating one"
  default     = true
}

variable "eks_cluster_service_role_arn" {
  type        = string
  description = <<-EOT
    The ARN of an IAM role for the EKS cluster to use that provides permissions
    for the Kubernetes control plane to perform needed AWS API operations.
    Required if `create_eks_service_role` is `false`, ignored otherwise.
    EOT
  default     = null
}

variable "workers_role_arns" {
  type        = list(string)
  description = "List of Role ARNs of the worker nodes"
  default     = []
}

variable "kubernetes_version" {
  type        = string
  description = "Desired Kubernetes master version. If you do not specify a value, the latest available version is used"
  default     = "1.21"
}

variable "oidc_provider_enabled" {
  type        = bool
  description = <<-EOT
    Create an IAM OIDC identity provider for the cluster, then you can create IAM roles to associate with a
    service account in the cluster, instead of using kiam or kube2iam. For more information,
    see [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html).
    EOT
  default     = false
}

variable "endpoint_private_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled. Default to AWS EKS resource and it is false"
  default     = false
}

variable "endpoint_public_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled. Default to AWS EKS resource and it is true"
  default     = true
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "Indicates which CIDR blocks can access the Amazon EKS public API server endpoint when enabled. EKS defaults this to a list with 0.0.0.0/0."
  default     = ["0.0.0.0/0"]
}

variable "service_ipv4_cidr" {
  type        = string
  description = <<-EOT
    The CIDR block to assign Kubernetes service IP addresses from.
    You can only specify a custom CIDR block when you create a cluster, changing this value will force a new cluster to be created.
    EOT
  default     = null
}

variable "kubernetes_network_ipv6_enabled" {
  type        = bool
  description = "Set true to use IPv6 addresses for Kubernetes pods and services"
  default     = false
}

variable "enabled_cluster_log_types" {
  type        = list(string)
  description = "A list of the desired control plane logging to enable. For more information, see https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. Possible values [`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`]"
  default     = []
}

variable "cluster_log_retention_period" {
  type        = number
  description = "Number of days to retain cluster logs. Requires `enabled_cluster_log_types` to be set. See https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html."
  default     = 0
}

variable "apply_config_map_aws_auth" {
  type        = bool
  description = "Whether to apply the ConfigMap to allow worker nodes to join the EKS cluster and allow additional users, accounts and roles to acces the cluster"
  default     = true
}

variable "map_additional_aws_accounts" {
  type        = list(string)
  description = "Additional AWS account numbers to add to `config-map-aws-auth` ConfigMap"
  default     = []
}

variable "map_additional_iam_roles" {
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  description = "Additional IAM roles to add to `config-map-aws-auth` ConfigMap"
  default     = []
}

variable "map_additional_iam_users" {
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  description = "Additional IAM users to add to `config-map-aws-auth` ConfigMap"
  default     = []
}

variable "local_exec_interpreter" {
  type        = list(string)
  description = "shell to use for local_exec"
  default     = ["/bin/sh", "-c"]
}

variable "wait_for_cluster_command" {
  type        = string
  description = "`local-exec` command to execute to determine if the EKS cluster is healthy. Cluster endpoint URL is available as environment variable `ENDPOINT`"
  ## --max-time is per attempt, --retry is the number of attempts
  ## Approx. total time limit is (max-time + retry-delay) * retry seconds
  default = "if test -n \"$ENDPOINT\"; then curl --silent --fail --retry 30 --retry-delay 10 --retry-connrefused --max-time 11 --insecure --output /dev/null $ENDPOINT/healthz; fi"
}

variable "kubernetes_config_map_ignore_role_changes" {
  type        = bool
  description = "Set to `true` to ignore IAM role changes in the Kubernetes Auth ConfigMap"
  default     = true
}

variable "cluster_encryption_config_enabled" {
  type        = bool
  description = "Set to `true` to enable Cluster Encryption Configuration"
  default     = true
}

variable "cluster_encryption_config_kms_key_id" {
  type        = string
  description = "KMS Key ID to use for cluster encryption config"
  default     = ""
}

variable "cluster_encryption_config_kms_key_enable_key_rotation" {
  type        = bool
  description = "Cluster Encryption Config KMS Key Resource argument - enable kms key rotation"
  default     = true
}

variable "cluster_encryption_config_kms_key_deletion_window_in_days" {
  type        = number
  description = "Cluster Encryption Config KMS Key Resource argument - key deletion windows in days post destruction"
  default     = 10
}

variable "cluster_encryption_config_kms_key_policy" {
  type        = string
  description = "Cluster Encryption Config KMS Key Resource argument - key policy"
  default     = null
}

variable "cluster_encryption_config_resources" {
  type        = list(any)
  description = "Cluster Encryption Config Resources to encrypt, e.g. ['secrets']"
  default     = ["secrets"]
}

variable "permissions_boundary" {
  type        = string
  description = "If provided, all IAM roles will be created with this permissions boundary attached"
  default     = null
}

variable "cloudwatch_log_group_kms_key_id" {
  type        = string
  description = "If provided, the KMS Key ID to use to encrypt AWS CloudWatch logs"
  default     = null
}

variable "addons" {
  type = list(object({
    addon_name               = string
    addon_version            = optional(string, null)
    configuration_values     = optional(string, null)
    resolve_conflicts        = string
    service_account_role_arn = optional(string, null)
    create_timeout           = optional(string, null)
    update_timeout           = optional(string, null)
    delete_timeout           = optional(string, null)
  }))
  description = "Manages [`aws_eks_addon`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) resources"
  default     = []
}

variable "addons_depends_on" {
  type        = any
  description = <<-EOT
    If provided, all addons will depend on this object, and therefore not be installed until this object is finalized.
    This is useful if you want to ensure that addons are not applied before some other condition is met, e.g. node groups are created.
    See [issue #170](https://github.com/cloudposse/terraform-aws-eks-cluster/issues/170) for more details.
    EOT
  default     = null
}

##################
# All the following variables are just about configuring the Kubernetes provider
# to be able to modify the aws-auth ConfigMap. Once EKS provides a normal
# AWS API for modifying it, we can do away with all of this.
#
# The reason there are so many options is because at various times, each
# one of them has had problems, so we give you a choice.
#
# The reason there are so many "enabled" inputs rather than automatically
# detecting whether or not they are enabled based on the value of the input
# is that any logic based on input values requires the values to be known during
# the "plan" phase of Terraform, and often they are not, which causes problems.
#

variable "kubeconfig_path_enabled" {
  type        = bool
  description = "If `true`, configure the Kubernetes provider with `kubeconfig_path` and use it for authenticating to the EKS cluster"
  default     = false
}

variable "kubeconfig_path" {
  type        = string
  description = "The Kubernetes provider `config_path` setting to use when `kubeconfig_path_enabled` is `true`"
  default     = ""
}

variable "kubeconfig_context" {
  type        = string
  description = "Context to choose from the Kubernetes kube config file"
  default     = ""
}

variable "kube_data_auth_enabled" {
  type        = bool
  description = <<-EOT
    If `true`, use an `aws_eks_cluster_auth` data source to authenticate to the EKS cluster.
    Disabled by `kubeconfig_path_enabled` or `kube_exec_auth_enabled`.
    EOT
  default     = true
}

variable "kube_exec_auth_enabled" {
  type        = bool
  description = <<-EOT
    If `true`, use the Kubernetes provider `exec` feature to execute `aws eks get-token` to authenticate to the EKS cluster.
    Disabled by `kubeconfig_path_enabled`, overrides `kube_data_auth_enabled`.
    EOT
  default     = false
}


variable "kube_exec_auth_role_arn" {
  type        = string
  description = "The role ARN for `aws eks get-token` to use"
  default     = ""
}

variable "kube_exec_auth_role_arn_enabled" {
  type        = bool
  description = "If `true`, pass `kube_exec_auth_role_arn` as the role ARN to `aws eks get-token`"
  default     = false
}

variable "kube_exec_auth_aws_profile" {
  type        = string
  description = "The AWS config profile for `aws eks get-token` to use"
  default     = ""
}

variable "kube_exec_auth_aws_profile_enabled" {
  type        = bool
  description = "If `true`, pass `kube_exec_auth_aws_profile` as the `profile` to `aws eks get-token`"
  default     = false
}

variable "aws_auth_yaml_strip_quotes" {
  type        = bool
  description = "If true, remove double quotes from the generated aws-auth ConfigMap YAML to reduce spurious diffs in plans"
  default     = true
}

variable "dummy_kubeapi_server" {
  type        = string
  default     = "https://jsonplaceholder.typicode.com"
  description = <<-EOT
    URL of a dummy API server for the Kubernetes server to use when the real one is unknown.
    This is a workaround to ignore connection failures that break Terraform even though the results do not matter.
    You can disable it by setting it to `null`; however, as of Kubernetes provider v2.3.2, doing so _will_
    cause Terraform to fail in several situations unless you provide a valid `kubeconfig` file
    via `kubeconfig_path` and set `kubeconfig_path_enabled` to `true`.
    EOT
}

variable "cluster_attributes" {
  type        = list(string)
  description = "Override label module default cluster attributes"
  default     = ["cluster"]
}

variable "managed_security_group_rules_enabled" {
  type        = bool
  description = "Flag to enable/disable the ingress and egress rules for the EKS managed Security Group"
  default     = true
}
