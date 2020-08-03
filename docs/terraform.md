## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.12.0 |
| aws | ~> 2.0 |
| kubernetes | ~> 1.11 |
| local | ~> 1.3 |
| null | ~> 2.0 |
| template | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 2.0 |
| kubernetes | ~> 1.11 |
| null | ~> 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| allowed\_cidr\_blocks | List of CIDR blocks to be allowed to connect to the EKS cluster | `list(string)` | `[]` | no |
| allowed\_security\_groups | List of Security Group IDs to be allowed to connect to the EKS cluster | `list(string)` | `[]` | no |
| apply\_config\_map\_aws\_auth | Whether to apply the ConfigMap to allow worker nodes to join the EKS cluster and allow additional users, accounts and roles to acces the cluster | `bool` | `true` | no |
| attributes | Additional attributes (e.g. `1`) | `list(string)` | `[]` | no |
| cluster\_encryption\_config\_kms\_key\_deletion\_window\_in\_days | Cluster Encryption Config KMS Key Resource argument - key deletion windows in days post destruction | `number` | `10` | no |
| cluster\_encryption\_config\_kms\_key\_enable\_key\_rotation | Cluster Encryption Config KMS Key Resource argument - enable kms key rotation | `bool` | `true` | no |
| cluster\_encryption\_config\_kms\_key\_id | Specify KMS Key Id ARN to use for cluster encryption config | `string` | `""` | no |
| cluster\_encryption\_config\_kms\_key\_policy | Cluster Encryption Config KMS Key Resource argument - key policy | `string` | `null` | no |
| cluster\_encryption\_config\_resources | Cluster Encryption Config Resources to encrypt, e.g. ['secrets'] | `list` | <pre>[<br>  "secrets"<br>]</pre> | no |
| cluster\_log\_retention\_period | Number of days to retain cluster logs. Requires `enabled_cluster_log_types` to be set. See https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. | `number` | `0` | no |
| delimiter | Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes` | `string` | `"-"` | no |
| enable\_cluster\_encryption\_config | Set to `true` to enable Cluster Encryption Configuration | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| enabled\_cluster\_log\_types | A list of the desired control plane logging to enable. For more information, see https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. Possible values [`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`] | `list(string)` | `[]` | no |
| endpoint\_private\_access | Indicates whether or not the Amazon EKS private API server endpoint is enabled. Default to AWS EKS resource and it is false | `bool` | `false` | no |
| endpoint\_public\_access | Indicates whether or not the Amazon EKS public API server endpoint is enabled. Default to AWS EKS resource and it is true | `bool` | `true` | no |
| environment | Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT' | `string` | `""` | no |
| kubernetes\_config\_map\_ignore\_role\_changes | Set to `true` to ignore IAM role changes in the Kubernetes Auth ConfigMap | `bool` | `true` | no |
| kubernetes\_version | Desired Kubernetes master version. If you do not specify a value, the latest available version is used | `string` | `"1.15"` | no |
| local\_exec\_interpreter | shell to use for local\_exec | `list(string)` | <pre>[<br>  "/bin/sh",<br>  "-c"<br>]</pre> | no |
| map\_additional\_aws\_accounts | Additional AWS account numbers to add to `config-map-aws-auth` ConfigMap | `list(string)` | `[]` | no |
| map\_additional\_iam\_roles | Additional IAM roles to add to `config-map-aws-auth` ConfigMap | <pre>list(object({<br>    rolearn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| map\_additional\_iam\_users | Additional IAM users to add to `config-map-aws-auth` ConfigMap | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | `string` | `""` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | `string` | `""` | no |
| oidc\_provider\_enabled | Create an IAM OIDC identity provider for the cluster, then you can create IAM roles to associate with a service account in the cluster, instead of using kiam or kube2iam. For more information, see https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html | `bool` | `false` | no |
| public\_access\_cidrs | Indicates which CIDR blocks can access the Amazon EKS public API server endpoint when enabled. EKS defaults this to a list with 0.0.0.0/0. | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| region | AWS Region | `string` | n/a | yes |
| stage | Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release' | `string` | `""` | no |
| subnet\_ids | A list of subnet IDs to launch the cluster in | `list(string)` | n/a | yes |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')` | `map(string)` | `{}` | no |
| vpc\_id | VPC ID for the EKS cluster | `string` | n/a | yes |
| wait\_for\_cluster\_command | `local-exec` command to execute to determine if the EKS cluster is healthy. Cluster endpoint are available as environment variable `ENDPOINT` | `string` | `"curl --silent --fail --retry 60 --retry-delay 5 --retry-connrefused --insecure --output /dev/null $ENDPOINT/healthz"` | no |
| workers\_role\_arns | List of Role ARNs of the worker nodes | `list(string)` | `[]` | no |
| workers\_security\_group\_ids | Security Group IDs of the worker nodes | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_encryption\_config\_provider\_key\_alias | Cluster Encryption Config KMS Key Alias ARN |
| cluster\_encryption\_config\_provider\_key\_arn | Cluster Encryption Config KMS Key ARN |
| cluster\_encryption\_config\_resources | Cluster Encryption Config Resources |
| eks\_cluster\_arn | The Amazon Resource Name (ARN) of the cluster |
| eks\_cluster\_certificate\_authority\_data | The Kubernetes cluster certificate authority data |
| eks\_cluster\_endpoint | The endpoint for the Kubernetes API server |
| eks\_cluster\_id | The name of the cluster |
| eks\_cluster\_identity\_oidc\_issuer | The OIDC Identity issuer for the cluster |
| eks\_cluster\_identity\_oidc\_issuer\_arn | The OIDC Identity issuer ARN for the cluster that can be used to associate IAM roles with a service account |
| eks\_cluster\_managed\_security\_group\_id | Security Group ID that was created by EKS for the cluster. EKS creates a Security Group and applies it to ENI that is attached to EKS Control Plane master nodes and to any managed workloads |
| eks\_cluster\_role\_arn | ARN of the EKS cluster IAM role |
| eks\_cluster\_version | The Kubernetes server version of the cluster |
| enable\_cluster\_encryption\_config | If true, Cluster Encryption Configuration is enabled |
| kubernetes\_config\_map\_id | ID of `aws-auth` Kubernetes ConfigMap |
| security\_group\_arn | ARN of the EKS cluster Security Group |
| security\_group\_id | ID of the EKS cluster Security Group |
| security\_group\_name | Name of the EKS cluster Security Group |