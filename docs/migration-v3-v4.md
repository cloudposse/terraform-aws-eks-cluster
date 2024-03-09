# Migration From Version 2 or 3 to Version 4

Users new to this module can skip this document and proceed to the main README.
This document is for users who are updating from version 2 or 3 to version 4.
It consists of 3 parts:

1. [Summary and Background](#summary-and-background): A brief overview of the 
   changes in version 4, what motivated them, and what they mean for you.
2. [Configuration Migration Overview](#configuration-migration-overview): A
   high-level overview of the changes you will need to make to your
   configuration to update to version 4. The inputs to this module have
   changed substantially, and you will need to update your configuration to
   match the new inputs.
2. [Configuration Migration Details](#configuration-migration-details): A
   detailed explanation of the changes you will need to make to your
   configuration to update to version 4. 
3. [Cluster Migration Steps](#cluster-migration-steps): Detailed instructions 
   for migrating your EKS cluster to be managed by version 4. After you have 
   updated your configuration, you will still need to take some additional 
   manual steps to have Terraform upgrade and manage your existing EKS 
   cluster with the new version 4 configuration. This step can be skipped if 
   you can tolerate simply creating a new EKS cluster and deleting the old one.


#### Usage notes

- We recommend leaving `bootstrap_cluster_creator_admin_permissions` set to
  `false`. When set to `true`, EKS automatically adds an access entry for the
  EKS cluster creator during creation, but this interferes with Terraform's
  management of the access entries, and it is not recommended for Terraform
  users. Note that now that there is an API for managing access to the EKS
  cluster, it is no longer necessary to have admin access to the cluster in
  order to manage access to it. You only need to have the separate IAM
  permission [`eks:CreateAccessEntry`](https://docs.aws.amazon.com/eks/latest/APIReference/API_CreateAccessEntry.html)
  to add an access entry to the cluster and `eks:AssociateAccessPolicy` to give
  that entry ClusterAdmin permissions.
- As of the release of version 4 of this module, it remains an issue that 
  AWS Identity Center auto-generates IAM roles with non-deterministic ARNs 
  to correspond to Permission Sets. Changes to the Permission Set will cause
  the ARN of the corresponding IAM role to change. This will invalidate any
  EKS Access Entry that used the old IAM role ARN, requiring you to remove 
  the old access entry and add the new one. Follow [`containers-roadmap`
  issue 474](https://github.com/aws/containers-roadmap/issues/474) for 
  updates on features that will mitigate this issue.
- For new clusters, we recommend setting `access_config.authentication_mode 
  = "API"` to use the new access control API exclusively. By default, the 
  module enables both the API and the `aws-auth` ConfigMap to allow for a 
  smooth transition from the old method to the new one.   

## Summary and Background

Version 4 of this module introduces several breaking changes that will 
require updates to your existing configuration. Major changes include:

- Removal of any management of the `aws-auth` ConfigMap. This module now 
  uses the AWS API to manage access to the EKS cluster, and no longer interacts
  with the ConfigMap directly in any way. 
- Removal of the Kubernetes Terraform provider. It was only used to interact with
  the `aws-auth` ConfigMap, and is no longer necessary.
- Addition of Kubernetes access control via the AWS API, specifically 
  Access Entries and Associated Access Policies.
- Replacement of inputs associated with configuring the `aws-auth` ConfigMap 
  with new inputs for configuring access control using the new AWS API. This 
  was done in part to ensure that there is no ambiguity about which format 
  of IAM Principal ARN is required, and what restrictions apply to the 
  Kubernetes group memberships.
- Restoration of the path component in any IAM Principal ARNs. When using 
  the legacy `aws-auth` ConfigMap, the path component in any IAM Principal 
  ARN had to be removed from the ARN, and the modified ARN was used in the
  ConfigMap. This was a workaround for a limitation in the AWS 
  Implementation. With full AWS API support for access control, the path 
  component is no longer removed, and the full ARN is required.
- Removal of any support for creating an additional Security Group for 
  worker nodes. This module now only allows some addition of rules to the 
  EKS-managed Security Group. Normally you would associate all worker nodes 
  with that Security Group. (Worker nodes can be associated with additional 
  Security Groups as well if desired.). This includes the removal of the 
  `vpc_id` input, which was only needed for creating the additional Security 
  Group.
- Replacement of `aws_security_group_rule` resources with the newer
  `aws_vpc_security_group_ingress_rule` resources for adding ingress rules to
  the EKS-managed Security Group. For people who were adding ingress rules to
  the EKS-managed Security Group, This will cause a brief interruption in
  communication as the old rules are removed and the new rules are added. The
  benefit is that you can then use the new
  `aws_vpc_security_group_ingress_rule` and
  `aws_vpc_security_group_egress_rule` resources to manage the rules in your
  root module or a separate component, allowing you much more control and
  flexibility over the rules than this module provides.

### Access to the EKS cluster

The primary credential used for accessing any AWS resource is your AWS IAM 
user or role, more generally referred to as an IAM principal. Previously,
EKS clusters contained a Kubernetes ConfigMap called `aws-auth` that was used
to map IAM principals to Kubernetes RBAC roles. This was the only way to
grant access to the EKS cluster, and this module managed the `aws-auth` ConfigMap
for you. However, managing a Kubernetes resource from Terraform was not ideal,
and managing any resource created by another resource in the same Terraform
configuration is not supported by Terraform.  Prior to v4, this module relied 
on a series of tricks to get around these limitations, but it was far from
a complete solution.

In v4, this module now uses the [new AWS API](https://github.com/aws/containers-roadmap/issues/185#issuecomment-1863025784)
to manage access to the EKS cluster and no longer interacts with the 
`aws-auth` ConfigMap directly.

### Security Groups

This module creates an EKS cluster, which automatically creates an EKS-managed
Security Group in which all managed nodes are placed automatically by EKS, and
unmanaged nodes could be placed by the user, to ensure the nodes and control
plane can communicate.

In version 2, there was legacy support for creating an additional Security Group 
for worker nodes. (See the [version 2 migration documentation]
(migration-v1-v2.md) for more information about the legacy support.) 
This support has been removed in version 4, and this module now only supports
some configuration of the EKS-managed Security Group, enabled by the
`managed_security_group_rules_enabled` variable.


## Configuration Migration Overview

If you are deploying a new EKS cluster with this module, no special steps 
need to be taken, although we recommend setting 
`access_config.authentication_mode = "API"` to use the new access control
API exclusively. By default, the module enables both the API and the `aws-auth`
ConfigMap to allow for a smooth transition from the old method to the new one.

### Removed variables

- Variables deprecated in version 2 have been removed in version 4. These 
  include anything related to creating or managing a Security Group 
  distinct from the one automatically created for the cluster by EKS.

- Any variables relating to the Kubernetes Terraform provider or the 
  `aws-auth` ConfigMap have been removed, and the provider itself has been 
  removed. 

- Any variables configuring access to the EKS cluster, such
  as `map_additional_iam_roles` and `workers_role_arns`, have been removed and
  replaced with new variables with names starting with `access_` that configure
  access control using the new AWS API.

### Removed outputs

- The `kubernetes_config_map_id` output has been removed, as the module no 
  longer manages the `aws-auth` ConfigMap. If you had been using this output 
  to "depend_on" before creating other resources, you probably no longer 
  need to configure an explicit dependency.

- Any outputs related to the additional Security Group have been removed.

## Configuration Migration Steps

### Access Control Configuration

The primary change in version 4 is the new way of configuring access to the
EKS cluster. This is done using the new AWS API for managing access to the
EKS cluster, specifically Access Entries and Associated Access Policies.
To support the transition of existing clusters, AWS now allows the cluster
to be in one of 3 configuration modes: "CONFIG_MAP", "API", or 
"API_AND_CONFIG_MAP". This module defaults to "API", which is the recommended
configuration for new clusters. However, existing clusters will be using the
"CONFIG_MAP" configuration (previously the only option available), and AWS 
does not support direct upgrade from "CONFIG_MAP" to "API". Therefore:

> [!NOTE]
> When updating an existing cluster, you will need to set `authentication_mode`
> to "API_AND_CONFIG_MAP" in your configuration, and then update the cluster.
> After the cluster has been updated, you can set `authentication_mode` to
> the default value of "API" and update the cluster again, but you cannot
> directly upgrade from "CONFIG_MAP" to "API".

### Consideration: Information Known and Unknown at Plan Time

Previously, all access control information could be unknown at plan time 
without causing any problems, because at plan time Terraform only cares about 
whether a resource (technically, a resource address) is created or not, and the 
single `aws-auth` ConfigMap was always created. 

Now, each piece of the access control configuration is a separate resource, 
which means it has to be created via either `count` or `for_each`. There are 
tradeoffs to both approaches, so you will have to decide which is best for
your situation. See [Count vs For Each](https://docs.cloudposse.com/reference/terraform-in-depth/terraform-count-vs-for-each/)
for a discussion of the issues that arise when creating resources from 
lists using `count`. 

To configure access using `for_each`, you can use the `access_entry_map` input.
This is the preferred approach, as it keeps any entry from changing
unnecessarily, but it requires that all IAM principal ARNs, Kubernetes group
memberships, and EKS access policy ARNs are known at plan time, and that 
none of them are designated as "sensitive".

If you cannot use `access_entry_map` for some entries, you can use it for
the ones that are known at plan time and use the pair of inputs `access_entries`
and `access_policy_associations` for the ones that are not. These inputs
take lists, and resources are created via `count`. There is a separate 
list-based input for self-managed nodes, `access_entries_for_nodes`, because 
nodes are managed differently from other access entries.

These list-based inputs only require you know the number of entries at plan 
time, not the specific entries themselves. However, this still means you cannot
use functions that can modify the length of the list, such as `compact` or, 
[prior to Terraform v1.6.0, `sort`](https://github.com/hashicorp/terraform/issues/31035).
See [Explicit Transformations of Lists]https://docs.cloudposse.com/reference/terraform-in-depth/terraform-unknown-at-plan-time/#explicit-transformations-of-lists)
for more information on limitations on list transformations.

### Migrating Access for Standard Users

Access for standard users is now configured using a combination of 
Kubernetes RBAC settings and the new [AWS EKS Access Policies](https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html#access-policy-permissions). 
As explained above under [Consideration: Information Known and Unknown at Plan Time](#consideration-information-known-and-unknown-at-plan-time), 
there are both map-based and list-based inputs for configuring access.

Whereas previously your only option was to assign IAM Principals to Kubernetes 
RBAC Groups, you can now also associate IAM Principals with EKS Access Policies.

Unfortunately, migration from the old method to the new one is not as  
straightforward as we would like. 

#### Restoration of the Path Component in IAM Principal ARNs

> [!WARNING]
> Previously, when using the `aws-auth` ConfigMap, the path component in any
> IAM Principal ARN had to be removed from the ARN, and the modified ARN was
> used in the ConfigMap. This was a workaround for a limitation in the AWS
> Implementation. With full AWS API support for access control, the path
> component is no longer removed, and the full ARN is required.
> 
> If you had been using the `aws-auth` ConfigMap, you should have been 
> removing the path component either manually as part of your static 
> configuration, or programmatically. You will need to undo these 
> transformations and provide the full ARN in the new configuration.

#### Migrating from Kubernetes RBAC Groups to EKS Access Policies

##### EKS Access Policy ARNs, Names, and Abbreviations

Previously, the only way to specify access to the EKS cluster was to assign
IAM Principals to Kubernetes RBAC Groups. Now, you can also associate IAM
Principals with EKS Access Policies. Full EKS Access Policy ARNs can be 
listed via the AWS CLI with the command `aws eks list-access-policies` and 
look like `arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy`. In 
AWS documentation and some other contexts, these policies are referred by 
name, for example `AmazonEKSAdminPolicy`. The name is the last component of
the ARN, and always matches the regex `^AmazonEKS(.*)Policy$`.

In this module, wherever an EKS Access Policy ARN is required, you can use
the full ARN, the full name (e.g. "AmazonEKSAdminPolicy"), or the 
abbreviated name (e.g. "Admin"). The abbreviated name is the `$1` part of the
regex `^AmazonEKS(.*)Policy$`. This document will usually use the abbreviated
name.

##### Changes to Kubernetes RBAC Groups

Previously, we created cluster administrators by assigning them to
the `system:masters` group. With the new AWS API, we can no longer assign any
users to any of the `system:*` groups. We have to create Cluster Administrators
by associating the ClusterAdmin policy with them, with type `cluster`.

> [!TIP]
> As a special case, the `system:masters` Kubernetes group is still supported by
> this module, but only when using `access_entry_map` and `type = "STANDARD"`. In
> this case, the `system:masters` group is automatically replaced with an
> association with the `ClusterAdmin` policy.

> [!NOTE]
> Note that this substitution is not done for `access_entries` because the 
> use case for `access_entries` is when values are not known at plan time, 
> and the substitution requires knowing the value at plan time.

Any other `system:*` groups, such as `system:bootstrappers` or `system:nodes` 
must be removed. (Those specific groups are assigned automatically by AWS 
when using `type` other than `STANDARD`.)

If you had been assigning users to any other Kubernetes RBAC groups, you can
continue to do so, and we recommend it.
At Cloud Posse, we have found that the pre-defined `view` and `edit` groups 
are unsatisfactory, because they do not allow access to Custom Resources,
and we expect the same limitations will make the View and Edit EKS Access 
Policies unsatisfactory. We bypass these limitations by creating our own 
groups and roles, and by enhancing the `view` role using the label:

```
rbac.authorization.k8s.io/aggregate-to-view: "true"
```

It is not clear whether changes to the `view` role affect the View EKS Access
Policy, but we expect that they do not, which is why we recommend continuing
to use Kubernetes RBAC groups for roles other than ClusterAdmin and Admin.

### Migrating Access for Self-Managed Nodes

There is almost nothing to configure to grant access to the EKS cluster for
nodes, as AWS handles everything fully automatically for EKS-managed nodes 
and Fargate nodes.

For self-managed nodes (which we no longer recommend using), you can use the
`access_entries_for_nodes` input, which is a pair of lists, one for Linux worker
nodes and one for Windows worker nodes. AWS manages all the access for these
nodes, so you only need to provide the IAM roles that the nodes will assume;
there is nothing else to configure.

The `access_entries_for_nodes` input roughly corresponds to the removed
`workers_role_arns` input, but requires separating Linux workers from 
Windows workers. There is no longer a need to configure Fargate nodes at all,
as that is fully automatic in the same way that EKS managed nodes are.


## Cluster Migration Steps

### Pt. 1: Prepare Your Configuration

#### Ensure your cluster satisfies the prerequisites

Verify that your cluster satisfies [the prerequisites](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.
html#access-entries-prerequisites) for using the new access control API.

#### Migrate your access control configuration

There is not exactly a rote transformation from the old access control
configuration to the new one, and there are some new wrinkles to consider.
Follow the guidance provided above under [Configuration Migration Steps](#configuration-migration-steps).

#### Migrate management of additional security group (if applicable)

For historical reasons, this module previously supported creating an
additional Security Group, with the idea that it would be used for worker 
nodes. You can find some more information about this in the [Migration From 
v1 to v2](migration-v1-v2.md#background) document.

If you had **not** set `create_security_group = true` in version 2 (you 
either set it to `false` or left it at its default value), you 
can skip this step. 

If you **had** set `create_security_group = true` and you do nothing about it
before updating to version 4, Terraform will try to remove the Security 
Group and most likely fail with a timeout error because the Security Group
is still associated with some resources. 

You have several options for how to proceed:

1. Manually delete the Security Group and remove any usage of it. It may be 
   that it was not being used, or it was being used in a redundant fashion 
   and thus was not needed. It may also be that it was being used to provide 
   this module with access to the EKS control plane, so that it could manage 
   the `aws-auth` ConfigMap. Since that access is no longer needed, you 
   might be able to safely delete the Security Group without any replacement.

1. Manually delete the Security Group and migrate any usage and 
   configuration of it to the EKS-managed Security Group. This is discussed 
   in the next section.

1. Manually delete the Security Group and create a new one in your root 
   module or a separate component, using our [security-group module](https://github.com/cloudposse/terraform-aws-security-group).


Because this is a complex operation with several options and potential
impacts, and because this feature had been deprecated for a long time, we are 
not providing further instructions here. If you need assistance with this,
please contact [Cloud Posse Professional Services](https://cloudposse.com/professional-services/)
for options and pricing.

#### Migrate management of EKS-managed security group (if applicable)

EKS creates a Security Group for the cluster, and all managed nodes are
automatically associated with that Security Group. The primary purpose of that 
security group is to enable communication between the nodes and the Kubernetes 
control plane.

When you create a node group for the cluster, even an EKS managed node group,
you can associate the nodes with additional Security Groups as well.
As a best practice, you would modify a node group Security Group to allow
communication between the nodes and other resources, such as a database, or
even the public internet via a NAT Gateway, while leaving the EKS managed 
Security Group alone, to protect the control plane. You would manage the 
rules for the node group's Security Group along with managing the node group.

However, people often instead modify the EKS-managed Security Group to allow
the necessary communication rather than create a separate Security group.
This was previously necessary in order to allow the v2 version of this
module to be able to manage the `aws-auth` ConfigMap via the Kubernetes
control plane.

Depending on your use cases and security posture, you may want to migrate 
existing access rules to a new security group, or you may want to modify the 
rules in the EKS-managed Security Group to allow the necessary communication.

This module retains some of the v2 features that allow you to add ingress 
rules to the EKS-managed Security Group, but it no longer allows you to 
create and manage a separate Security Group for worker nodes, as explained 
above.

To make changes to the EKS-managed Security Group, we recommend that 
you either directly use the `aws_vpc_security_group_ingress_rule` and
`aws_vpc_security_group_egress_rule` resources in your root module, or use a 
specialized module such as Cloud Posse's [security-group module]
(https://github.com/cloudposse/terraform-aws-security-group) (once v3 is 
released) to manage the rules. This will give you much more control and
flexibility over the rules than this module provides.

For backward compatibility, this module still supports adding ingress
rules to the EKS-managed Security Group, which may be sufficient for the 
simple case of allowing ingress from anything in your VPC. To use this
feature:

1. Set `managed_security_group_rules_enabled = true` in your configuration. 
   Without this, any other settings affecting the security group will be 
   ignored.
2. Allow all ingress from designated security groups by adding their IDs to 
   `allowed_security_group_ids`.
3. Allow all ingress from designated CIDR blocks by adding them to 
   `allowed_cidr_blocks`.
4. You can add more fine-grained ingress rules via the 
   `custom_ingress_rules` input, but this input requires that the source 
   security group ID be known at plan time and that there is no more than 
   one single rule per source security group.


### Pt. 2: No Going Back

> [!WARNING]
> Once you proceed with the following steps, there is no going back.
> AWS will not allow you to disable the new access control API once it is
> enabled, and restoring this modules access to the `aws-auth` ConfigMap
> will be difficult if not impossible, and we do not support it.

#### Update your module reference to v4

Update your module reference to version 4.0.0 or later in your root module or 
component. Ensure that you have updated all the inputs to the module to match
the new inputs.

Run `terraform plan` and fix any errors you get, such as "Unsupported 
argument", until the only error you are left with is something like:

```plaintext
Error: Provider configuration not present
│
│ To work with module.eks_cluster.kubernetes_config_map.aws_auth[0] (orphan) 
| its original provider configuration at ... is required, but it has been removed.
```

#### Remove the `auth-map` from the Terraform state

Take the "resource address" of the `auth-map` from the error message (the 
part before "`(orphan)`") and remove it from the terraform state. Using the 
address from the error message above, you would run:

```shell
terraform state rm 'module.eks_cluster.kubernetes_config_map.aws_auth[0]'
```

It is important to include the single quotes around the address, because 
otherwise `[0]` would be interpreted as a shell glob.

Run `terraform plan` again, at which point you should see no errors.

#### Review the changes

You should review the changes that Terraform is planning to make to your
cluster. Calmly. Expect some changes.

- `...null_resource.wait_for_cluster[0]` will be **destroyed**. This is 
  expected, because it was part of the old method of managing the `aws-auth` ConfigMap.
- Various `aws_security_group_rule` resources will be **destroyed**. They 
  should be replaced with corresponding 
  `aws_vpc_security_group_ingress_rule` resources. Note that if you had 
  specified multiple ingress CIDRs in `allowed_cidr_blocks`, the used to be 
  managed by a single `aws_security_group_rule` resource, but now each CIDR 
  is managed by a separate `aws_vpc_security_group_ingress_rule` resource, 
  so you may see more rule resources being created than destroyed.
- `...aws_eks_cluster.default[0]` will be **updated**. This is expected, 
  because the `authentication_mode` is changing from "CONFIG_MAP" to
  "API_AND_CONFIG_MAP". This is the main point of this upgrade.
- Expect to see resources of `aws_eks_access_entry` and 
  `aws_eks_access_policy_association` being **created**. These are the new 
  resources that manage access to the EKS cluster, replacing the entries in 
  the old `aws-auth` ConfigMap.
- You will likely see changes to `...aws_iam_openid_connect_provider.default[0]`. 
  This is because it depends on the `aws_eks_cluster` resource, specifically 
  its TLS certificate, and the `aws_eks_cluster` resource is being updated, 
  so Terraform cannot be sure that the OIDC provider will not need to be 
  updated as well. This is expected and harmless.
- You will likely see changes to IRSA (service account role) resources. This 
  is because they depend on the OIDC provider, and the OIDC provider may 
  need to be updated. This is expected and harmless.

#### Apply the changes

Apply the changes with `terraform apply` and verify you still have access to
the cluster and that everything is working as expected.

##### Error: creating EKS Access Entry

You may get an error message like this:

```plaintext
Error: creating EKS Access Entry 
(eg-test-eks-cluster:arn:aws:iam::123456789012:role/eg-test-terraform):
 operation error EKS: CreateAccessEntry, 
 https response error StatusCode: 409, RequestID: ..., ResourceInUseException: 
 The specified access entry resource is already in use on this cluster.
```

This is because, during the conversion from "CONFIG_MAP" to 
"API_AND_CONFIG_MAP", EKS automatically adds an access entry for the EKS
cluster creator. 

If you have been following Cloud Posse's recommendations, you will have 
configured ClusterAdmin access for the IAM principal that you used to create 
the EKS cluster. This configuration duplicates the automatically created access 
entry, resulting in the above error.

We have not found a way to avoid this situation, so our best recommendation is,
if you encounter it, import the automatically created access entry into your
Terraform state. The `access entry ID` to import is given in the error
message in parentheses. In the example above, the ID is
`eg-test-eks-cluster:arn:aws:iam::123456789012:role/eg-test-terraform`.

The Terraform `resource address` for the resource will depend on your usage. 
Probably the easiest way to find it is to run `terraform plan` and look for the 
corresponding access entry resource that Terraform will want to create. It 
will be something like 

```plaintext
...aws_eks_access_entry.map["arn:aws:iam::123456789012:role/eg-test-terraform"]
```

although it may be `standard` instead of `map`.

To import the resource using `atmos`, use the same component and stack name
as you were using to deploy the cluster, and run a command like

```shell
atmos terraform import <component> \
  <resource address> <access entry ID> \
  -s=<stack>
```

To import the resource using Terraform, again, you need to supply the same 
configuration that you used to deploy the cluster, and run a command like

```shell
terraform import -var-file <configuration-file> <resource address> <access entry ID>
```

After successfully importing the resource, run `terraform apply` again to 
add tags to the entry and verify that no other changes are outstanding.

#### Clean up

At this point you have both the old and new access control methods enabled,
but nothing is managing the `aws-auth` ConfigMap. You can now proceed to
migrate the cluster to be managed solely by the new access control API, and 
manually remove the `aws-auth` ConfigMap.

- Update the `authentication_mode` to "API" in your configuration, and run 
  `terraform apply` again. This will cause EKS to ignore the `aws-auth` 
  ConfigMap, but will not remove it.
- Manually remove the `aws-auth` ConfigMap. You can do this with `kubectl 
  delete configmap aws-auth --namespace kube-system`. This will not affect 
  the cluster, because it is now being managed by the new access control API,
  but it will reduce the possibility of confusion in the future.


