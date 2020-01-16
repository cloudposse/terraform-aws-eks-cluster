## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allowed_cidr_blocks | List of CIDR blocks to be allowed to connect to the EKS cluster | list(string) | `<list>` | no |
| allowed_security_groups | List of Security Group IDs to be allowed to connect to the EKS cluster | list(string) | `<list>` | no |
| apply_config_map_aws_auth | Whether to generate local files from `kubeconfig` and `config-map-aws-auth` templates and perform `kubectl apply` to apply the ConfigMap to allow worker nodes to join the EKS cluster | bool | `true` | no |
| associate_public_ip_address | Associate a public IP address with an instance in a VPC | bool | `true` | no |
| attributes | Additional attributes (e.g. `1`) | list(string) | `<list>` | no |
| aws_cli_assume_role_arn | IAM Role ARN for AWS CLI to assume before calling `aws eks` to update `kubeconfig` | string | `` | no |
| aws_cli_assume_role_session_name | An identifier for the assumed role session when assuming the IAM Role for AWS CLI before calling `aws eks` to update `kubeconfig` | string | `` | no |
| aws_eks_update_kubeconfig_additional_arguments | Additional arguments for `aws eks update-kubeconfig` command, e.g. `--role-arn xxxxxxxxx`. For more info, see https://docs.aws.amazon.com/cli/latest/reference/eks/update-kubeconfig.html | string | `` | no |
| configmap_auth_file | Path to `configmap_auth_file` | string | `` | no |
| configmap_auth_template_file | Path to `config_auth_template_file` | string | `` | no |
| delimiter | Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes` | string | `-` | no |
| enabled | Set to false to prevent the module from creating any resources | bool | `true` | no |
| enabled_cluster_log_types | A list of the desired control plane logging to enable. For more information, see https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. Possible values [`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`] | list(string) | `<list>` | no |
| endpoint_private_access | Indicates whether or not the Amazon EKS private API server endpoint is enabled. Default to AWS EKS resource and it is false | bool | `false` | no |
| endpoint_public_access | Indicates whether or not the Amazon EKS public API server endpoint is enabled. Default to AWS EKS resource and it is true | bool | `true` | no |
| environment | Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT' | string | `` | no |
| external_packages_install_path | Path to install external packages, e.g. AWS CLI and `kubectl`. Used when the module is provisioned on workstations where the external packages are not installed by default, e.g. Terraform Cloud workers | string | `` | no |
| install_aws_cli | Set to `true` to install AWS CLI if the module is provisioned on workstations where AWS CLI is not installed by default, e.g. Terraform Cloud workers | bool | `false` | no |
| install_kubectl | Set to `true` to install `kubectl` if the module is provisioned on workstations where `kubectl` is not installed by default, e.g. Terraform Cloud workers | bool | `false` | no |
| jq_version | Version of `jq` to download to extract temporaly credentials after running `aws sts assume-role` if AWS CLI needs to assume role to access the cluster (if variable `aws_cli_assume_role_arn` is set) | string | `1.6` | no |
| kubeconfig_path | The path to `kubeconfig` file | string | `~/.kube/config` | no |
| kubectl_version | `kubectl` version to install. If not specified, the latest version will be used | string | `` | no |
| kubernetes_version | Desired Kubernetes master version. If you do not specify a value, the latest available version is used | string | `1.14` | no |
| local_exec_interpreter | shell to use for local exec | string | `/bin/bash` | no |
| map_additional_aws_accounts | Additional AWS account numbers to add to `config-map-aws-auth` ConfigMap | list(string) | `<list>` | no |
| map_additional_iam_roles | Additional IAM roles to add to `config-map-aws-auth` ConfigMap | object | `<list>` | no |
| map_additional_iam_users | Additional IAM users to add to `config-map-aws-auth` ConfigMap | object | `<list>` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | string | `` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | string | `` | no |
| oidc_provider_enabled | Create an IAM OIDC identity provider for the cluster, then you can create IAM roles to associate with a service account in the cluster, instead of using kiam or kube2iam. For more information, see https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html | bool | `false` | no |
| region | AWS Region | string | - | yes |
| stage | Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release' | string | `` | no |
| subnet_ids | A list of subnet IDs to launch the cluster in | list(string) | - | yes |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')` | map(string) | `<map>` | no |
| vpc_id | VPC ID for the EKS cluster | string | - | yes |
| workers_role_arns | List of Role ARNs of the worker nodes | list(string) | - | yes |
| workers_security_group_ids | Security Group IDs of the worker nodes | list(string) | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| eks_cluster_arn | The Amazon Resource Name (ARN) of the cluster |
| eks_cluster_certificate_authority_data | The Kubernetes cluster certificate authority data |
| eks_cluster_endpoint | The endpoint for the Kubernetes API server |
| eks_cluster_id | The name of the cluster |
| eks_cluster_identity_oidc_issuer | The OIDC Identity issuer for the cluster |
| eks_cluster_identity_oidc_issuer_arn | The OIDC Identity issuer ARN for the cluster that can be used to associate IAM roles with a service account |
| eks_cluster_version | The Kubernetes server version of the cluster |
| security_group_arn | ARN of the EKS cluster Security Group |
| security_group_id | ID of the EKS cluster Security Group |
| security_group_name | Name of the EKS cluster Security Group |

