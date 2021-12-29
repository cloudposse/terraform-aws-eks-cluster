# Migration from 0.44.x to 0.45.x+

Version `0.45.0` of this module introduces breaking changes that, without taking additional precautions, will cause the EKS cluster to be recreated.

This is because version `0.45.0` relies on the [terraform-aws-security-group](https://github.com/cloudposse/terraform-aws-security-group)
module for managing the cluster Security Group. This changes the Terraform resource address for the Security Group, which will cause Terraform to recreate the SG.

To circumvent this, after bumping the module version to `0.45.0` (or above), run a plan to retrieve the resource address of the SG that Terraform would like to destroy, and the resource
address of the SG which Terraform would like to create.

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
