# Migration from 0.44.x to 0.45.x+

Version `0.45.0` of this module introduces potential breaking changes that, without taking additional precautions, could cause the EKS cluster to be recreated.

This is because version `0.45.0` relies on the [terraform-aws-security-group](https://github.com/cloudposse/terraform-aws-security-group)
module for managing a Security Group for the cluster. This changes the Terraform resource address for the Security Group, which will cause Terraform to recreate it.

## Background

This module creates an EKS cluster, which automatically creates an EKS-managed Security Group in which all managed nodes are placed automatically by EKS, and unmanaged nodes could be placed
by the user, to ensure the nodes and control plane can communicate.

Before version `0.45.0`, this module, by default, created an additional Security Group. Prior to version `0.19.0` of this module, that additional Security Group was the only one exposed by
this module (because EKS at the time did not create the managed Security Group for the cluster), and it was intended that all worker nodes (managed and unmanaged) be placed in this
additional Security Group. With version `0.19.0`, this module exposed the managed Security Group created by the EKS cluster, in which all managed node groups are placed by default. We now
recommend placing non-managed node groups in the EKS-created Security Group as well.

We would want to create a new Security Group only if the EKS cluster is used with unmanaged worker nodes. EKS creates a managed Security Group for the cluster automatically, places the
control plane and managed nodes into the security group, and allows all communications between the control plane and the managed worker nodes

If only Managed Node Groups are used, we don't need to create a separate Security Group; otherwise we place the cluster in two SGs - one that is created by EKS, the other one that the module
creates.

See https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html for more details.

## Migration Process

To circumvent this, after bumping the module version to `0.45.0` (or above), run a terraform plan to retrieve the resource address of the SG that Terraform would like to destroy, and the
resource address of the SG which Terraform would like to create.

First, make sure that the following variable is set:

```hcl
security_group_description = "Security Group for EKS cluster"
```

Setting `security_group_description` to its "legacy" value will keep the Security Group from being replaced, and hence the EKS cluster from being recreated.

Finally, change the resource address of the existing Security Group.

```bash
$ terraform state mv  "...aws_security_group.default[0]" "...module.eks_cluster.aws_security_group.default[0]" 
```

This will result in a Terraform apply that will only destroy SG Rules, but not the Security Group itself or the EKS cluster.
