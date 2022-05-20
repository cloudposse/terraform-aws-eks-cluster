# Migration From Version 1 to Version 2

Version 2 (a.k.a version 0.45.0) of this module introduces potential breaking changes that, without taking additional precautions, could cause the EKS cluster to be recreated.

## Background

This module creates an EKS cluster, which automatically creates an EKS-managed Security Group in which all managed nodes are placed automatically by EKS, and unmanaged nodes could be placed
by the user, to ensure the nodes and control plane can communicate.

Before version 2, this module, by default, created an additional Security Group. Prior to version `0.19.0` of this module, that additional Security Group was the only one exposed by
this module (because EKS at the time did not create the managed Security Group for the cluster), and it was intended that all worker nodes (managed and unmanaged) be placed in this
additional Security Group. With version `0.19.0`, this module exposed the managed Security Group created by the EKS cluster, in which all managed node groups are placed by default. We now
recommend placing non-managed node groups in the EKS-created Security Group as well by using the `allowed_security_group_ids` variable, and not create an additional Security Group.

See https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html for more details.

## Migration process

If you are deploying a new EKS cluster with this module, no special steps need to be taken. Just keep the variable `create_security_group` set to `false` to not create an additional Security
Group. Don't use the deprecated variables (see `variables-deprecated.tf`).

If you are updating this module to the latest version on existing (already deployed) EKS clusters, set the variable `create_security_group` to `true` to enable the additional Security Group
and all the rules (which were enabled by default in the previous releases of this module).

## Deprecated variables

Some variables have been deprecated (see `variables-deprecated.tf`), don't use them when creating new EKS clusters.

- Use `allowed_security_group_ids` instead of `allowed_security_groups` and `workers_security_group_ids`

- When using unmanaged worker nodes (e.g. with https://github.com/cloudposse/terraform-aws-eks-workers module), provide the worker nodes Security Groups to the cluster using
  the `allowed_security_group_ids` variable, for example:

  ```hcl
  module "eks_workers" {
    source = "cloudposse/eks-workers/aws"
  }

  module "eks_workers_2" {
    source = "cloudposse/eks-workers/aws"
  }
  
  module "eks_cluster" {
    source = "cloudposse/eks-cluster/aws"
    allowed_security_group_ids = [module.eks_workers.security_group_id, module.eks_workers_2.security_group_id]
  }
  ```
