## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allowed_cidr_blocks | List of CIDR blocks to be allowed to connect to the EKS cluster | list | `<list>` | no |
| allowed_security_groups | List of Security Group IDs to be allowed to connect to the EKS cluster | list | `<list>` | no |
| attributes | Additional attributes (e.g. `1`) | list | `<list>` | no |
| delimiter | Delimiter to be used between `name`, `namespace`, `stage`, etc. | string | `-` | no |
| enabled | Whether to create the resources. Set to `false` to prevent the module from creating any resources | string | `true` | no |
| enabled_cluster_log_types | A list of the desired control plane logging to enable. For more information, see https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. Possible values [api,audit,authenticator,controllerManager,scheduler] | list | `<list>` | no |
| endpoint_private_access | Indicates whether or not the Amazon EKS private API server endpoint is enabled. Default to AWS EKS resource and it is false | string | `false` | no |
| endpoint_public_access | Indicates whether or not the Amazon EKS public API server endpoint is enabled. Default to AWS EKS resource and it is is true | string | `true` | no |
| environment | Environment, e.g. 'testing', 'UAT' | string | `` | no |
| kubernetes_version | Desired Kubernetes master version. If you do not specify a value, the latest available version is used. | string | `` | no |
| name | Solution name, e.g. 'app' or 'cluster' | string | `app` | no |
| namespace | Namespace, which could be your organization name, e.g. 'eg' or 'cp' | string | - | yes |
| stage | Stage, e.g. 'prod', 'staging', 'dev', or 'test' | string | - | yes |
| subnet_ids | A list of subnet IDs to launch the cluster in | list | - | yes |
| tags | Additional tags (e.g. `map('BusinessUnit`,`XYZ`) | map | `<map>` | no |
| vpc_id | VPC ID for the EKS cluster | string | - | yes |
| workers_security_group_count | Count of the worker Security Groups. Needed to prevent Terraform error `count can't be computed` | string | - | yes |
| workers_security_group_ids | Security Group IDs of the worker nodes | list | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| eks_cluster_arn | The Amazon Resource Name (ARN) of the cluster |
| eks_cluster_certificate_authority_data | The base64 encoded certificate data required to communicate with the cluster |
| eks_cluster_endpoint | The endpoint for the Kubernetes API server |
| eks_cluster_id | The name of the cluster |
| eks_cluster_version | The Kubernetes server version of the cluster |
| kubeconfig | `kubeconfig` configuration to connect to the cluster using `kubectl`. https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#configuring-kubectl-for-eks |
| security_group_arn | ARN of the EKS cluster Security Group |
| security_group_id | ID of the EKS cluster Security Group |
| security_group_name | Name of the EKS cluster Security Group |

