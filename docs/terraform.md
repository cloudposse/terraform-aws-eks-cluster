## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allowed_cidr_blocks | List of CIDR blocks to be allowed to connect to the EKS cluster | list(string) | `<list>` | no |
| allowed_security_groups | List of Security Group IDs to be allowed to connect to the EKS cluster | list(string) | `<list>` | no |
| apply_config_map_aws_auth | Whether to apply the ConfigMap to allow worker nodes to join the EKS cluster and allow additional users, accounts and roles to acces the cluster | bool | `true` | no |
| attributes | Additional attributes (e.g. `1`) | list(string) | `<list>` | no |
| cluster_log_retention_period | Number of days to retain cluster logs. Requires `enabled_cluster_log_types` to be set. See https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. | number | `0` | no |
| delimiter | Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes` | string | `-` | no |
| enabled | Set to false to prevent the module from creating any resources | bool | `true` | no |
| enabled_cluster_log_types | A list of the desired control plane logging to enable. For more information, see https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. Possible values [`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`] | list(string) | `<list>` | no |
| endpoint_private_access | Indicates whether or not the Amazon EKS private API server endpoint is enabled. Default to AWS EKS resource and it is false | bool | `false` | no |
| endpoint_public_access | Indicates whether or not the Amazon EKS public API server endpoint is enabled. Default to AWS EKS resource and it is true | bool | `true` | no |
| environment | Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT' | string | `` | no |
| kubernetes_config_map_ignore_role_changes | Set to `true` to ignore IAM role changes in the Kubernetes Auth ConfigMap | bool | `true` | no |
| kubernetes_version | Desired Kubernetes master version. If you do not specify a value, the latest available version is used | string | `1.15` | no |
| local_exec_interpreter | shell to use for local_exec | list(string) | `<list>` | no |
| map_additional_aws_accounts | Additional AWS account numbers to add to `config-map-aws-auth` ConfigMap | list(string) | `<list>` | no |
| map_additional_iam_roles | Additional IAM roles to add to `config-map-aws-auth` ConfigMap | object | `<list>` | no |
| map_additional_iam_users | Additional IAM users to add to `config-map-aws-auth` ConfigMap | object | `<list>` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | string | `` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | string | `` | no |
| oidc_provider_enabled | Create an IAM OIDC identity provider for the cluster, then you can create IAM roles to associate with a service account in the cluster, instead of using kiam or kube2iam. For more information, see https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html | bool | `false` | no |
| public_access_cidrs | Indicates which CIDR blocks can access the Amazon EKS public API server endpoint when enabled. EKS defaults this to a list with 0.0.0.0/0. | list(string) | `<list>` | no |
| region | AWS Region | string | - | yes |
| stage | Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release' | string | `` | no |
| subnet_ids | A list of subnet IDs to launch the cluster in | list(string) | - | yes |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')` | map(string) | `<map>` | no |
| vpc_id | VPC ID for the EKS cluster | string | - | yes |
| wait_for_cluster_command | `local-exec` command to execute to determine if the EKS cluster is healthy. Cluster endpoint are available as environment variable `ENDPOINT` | string | `curl --silent --fail --retry 60 --retry-delay 5 --retry-connrefused --insecure --output /dev/null $ENDPOINT/healthz` | no |
| workers_role_arns | List of Role ARNs of the worker nodes | list(string) | `<list>` | no |
| workers_security_group_ids | Security Group IDs of the worker nodes | list(string) | `<list>` | no |

## Outputs

| Name | Description |
|------|-------------|
| eks_cluster_arn | The Amazon Resource Name (ARN) of the cluster |
| eks_cluster_certificate_authority_data | The Kubernetes cluster certificate authority data |
| eks_cluster_endpoint | The endpoint for the Kubernetes API server |
| eks_cluster_id | The name of the cluster |
| eks_cluster_identity_oidc_issuer | The OIDC Identity issuer for the cluster |
| eks_cluster_identity_oidc_issuer_arn | The OIDC Identity issuer ARN for the cluster that can be used to associate IAM roles with a service account |
| eks_cluster_managed_security_group_id | Security Group ID that was created by EKS for the cluster. EKS creates a Security Group and applies it to ENI that is attached to EKS Control Plane master nodes and to any managed workloads |
| eks_cluster_role_arn | ARN of the EKS cluster IAM role |
| eks_cluster_version | The Kubernetes server version of the cluster |
| kubernetes_config_map_id | ID of `aws-auth` Kubernetes ConfigMap |
| security_group_arn | ARN of the EKS cluster Security Group |
| security_group_id | ID of the EKS cluster Security Group |
| security_group_name | Name of the EKS cluster Security Group |

