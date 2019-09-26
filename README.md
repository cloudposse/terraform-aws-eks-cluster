<!-- This file was automatically generated by the `build-harness`. Make all changes to `README.yaml` and run `make readme` to rebuild this file. -->
[![README Header][readme_header_img]][readme_header_link]

[![Cloud Posse][logo]](https://cpco.io/homepage)

# terraform-aws-eks-cluster [![Codefresh Build Status](https://g.codefresh.io/api/badges/pipeline/cloudposse/terraform-modules%2Fterraform-aws-eks-cluster?type=cf-1)](https://g.codefresh.io/public/accounts/cloudposse/pipelines/5d8cd583941e46a098d3992d) [![Latest Release](https://img.shields.io/github/release/cloudposse/terraform-aws-eks-cluster.svg)](https://github.com/cloudposse/terraform-aws-eks-cluster/releases/latest) [![Slack Community](https://slack.cloudposse.com/badge.svg)](https://slack.cloudposse.com)


Terraform module to provision an [EKS](https://aws.amazon.com/eks/) cluster on AWS.


---

This project is part of our comprehensive ["SweetOps"](https://cpco.io/sweetops) approach towards DevOps. 
[<img align="right" title="Share via Email" src="https://docs.cloudposse.com/images/ionicons/ios-email-outline-2.0.1-16x16-999999.svg"/>][share_email]
[<img align="right" title="Share on Google+" src="https://docs.cloudposse.com/images/ionicons/social-googleplus-outline-2.0.1-16x16-999999.svg" />][share_googleplus]
[<img align="right" title="Share on Facebook" src="https://docs.cloudposse.com/images/ionicons/social-facebook-outline-2.0.1-16x16-999999.svg" />][share_facebook]
[<img align="right" title="Share on Reddit" src="https://docs.cloudposse.com/images/ionicons/social-reddit-outline-2.0.1-16x16-999999.svg" />][share_reddit]
[<img align="right" title="Share on LinkedIn" src="https://docs.cloudposse.com/images/ionicons/social-linkedin-outline-2.0.1-16x16-999999.svg" />][share_linkedin]
[<img align="right" title="Share on Twitter" src="https://docs.cloudposse.com/images/ionicons/social-twitter-outline-2.0.1-16x16-999999.svg" />][share_twitter]


[![Terraform Open Source Modules](https://docs.cloudposse.com/images/terraform-open-source-modules.svg)][terraform_modules]



It's 100% Open Source and licensed under the [APACHE2](LICENSE).







We literally have [*hundreds of terraform modules*][terraform_modules] that are Open Source and well-maintained. Check them out! 






## Introduction

The module provisions the following resources:

- EKS cluster of master nodes that can be used together with the [terraform-aws-eks-workers](https://github.com/cloudposse/terraform-aws-eks-workers) module to create a full-blown cluster
- IAM Role to allow the cluster to access other AWS services
- Security Group which is used by EKS workers to connect to the cluster and kubelets and pods to receive communication from the cluster control plane (see [terraform-aws-eks-workers](https://github.com/cloudposse/terraform-aws-eks-workers))
- The module generates `kubeconfig` configuration to connect to the cluster using `kubectl`

## Usage


**IMPORTANT:** The `master` branch is used in `source` just as an example. In your code, do not pin to `master` because there may be breaking changes between releases.
Instead pin to the release tag (e.g. `?ref=tags/x.y.z`) of one of our [latest releases](https://github.com/cloudposse/terraform-aws-eks-cluster/releases).



Module usage examples:

- [examples/complete](examples/complete) - complete example
- [terraform-root-modules/eks](https://github.com/cloudposse/terraform-root-modules/tree/master/aws/eks) - Cloud Posse's service catalog of "root module" invocations for provisioning reference architectures
- [terraform-root-modules/eks-backing-services-peering](https://github.com/cloudposse/terraform-root-modules/tree/master/aws/eks-backing-services-peering) - example of VPC peering between the EKS VPC and backing services VPC

```hcl
  provider "aws" {
    region = var.region
  }

  module "label" {
    source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=master"
    namespace  = var.namespace
    name       = var.name
    stage      = var.stage
    delimiter  = var.delimiter
    attributes = compact(concat(var.attributes, list("cluster")))
    tags       = var.tags
  }

  locals {
    # The usage of the specific kubernetes.io/cluster/* resource tags below are required
    # for EKS and Kubernetes to discover and manage networking resources
    # https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#base-vpc-networking
    tags = merge(var.tags, map("kubernetes.io/cluster/${module.label.id}", "shared"))
  }

  module "vpc" {
    source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=master"
    namespace  = var.namespace
    stage      = var.stage
    name       = var.name
    attributes = var.attributes
    cidr_block = "172.16.0.0/16"
    tags       = local.tags
  }

  module "subnets" {
    source               = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=master"
    availability_zones   = var.availability_zones
    namespace            = var.namespace
    stage                = var.stage
    name                 = var.name
    attributes           = var.attributes
    vpc_id               = module.vpc.vpc_id
    igw_id               = module.vpc.igw_id
    cidr_block           = module.vpc.vpc_cidr_block
    nat_gateway_enabled  = false
    nat_instance_enabled = false
    tags                 = local.tags
  }

  module "eks_workers" {
    source                             = "git::https://github.com/cloudposse/terraform-aws-eks-workers.git?ref=master"
    namespace                          = var.namespace
    stage                              = var.stage
    name                               = var.name
    attributes                         = var.attributes
    tags                               = var.tags
    instance_type                      = var.instance_type
    vpc_id                             = module.vpc.vpc_id
    subnet_ids                         = module.subnets.public_subnet_ids
    health_check_type                  = var.health_check_type
    min_size                           = var.min_size
    max_size                           = var.max_size
    wait_for_capacity_timeout          = var.wait_for_capacity_timeout
    cluster_name                       = module.label.id
    cluster_endpoint                   = module.eks_cluster.eks_cluster_endpoint
    cluster_certificate_authority_data = module.eks_cluster.eks_cluster_certificate_authority_data
    cluster_security_group_id          = module.eks_cluster.security_group_id

    # Auto-scaling policies and CloudWatch metric alarms
    autoscaling_policies_enabled           = var.autoscaling_policies_enabled
    cpu_utilization_high_threshold_percent = var.cpu_utilization_high_threshold_percent
    cpu_utilization_low_threshold_percent  = var.cpu_utilization_low_threshold_percent
  }

  module "eks_cluster" {
    source     = "git::https://github.com/cloudposse/terraform-aws-eks-cluster.git?ref=master"
    namespace  = var.namespace
    stage      = var.stage
    name       = var.name
    attributes = var.attributes
    tags       = var.tags
    vpc_id     = module.vpc.vpc_id
    subnet_ids = module.subnets.public_subnet_ids

    # `workers_security_group_count` is needed to prevent `count can't be computed` errors
    workers_security_group_ids   = [module.eks_workers.security_group_id]
    workers_security_group_count = 1

    workers_role_arns = [module.eks_workers.workers_role_arn]
  }
```






## Makefile Targets
```
Available targets:

  help                                Help screen
  help/all                            Display help for all targets
  help/short                          This help short screen
  lint                                Lint terraform code

```
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allowed_cidr_blocks | List of CIDR blocks to be allowed to connect to the EKS cluster | list(string) | `<list>` | no |
| allowed_security_groups | List of Security Group IDs to be allowed to connect to the EKS cluster | list(string) | `<list>` | no |
| apply_config_map_aws_auth | Whether to generate local files from `kubeconfig` and `config-map-aws-auth` templates and perform `kubectl apply` to apply the ConfigMap to allow worker nodes to join the EKS cluster | bool | `true` | no |
| attributes | Additional attributes (e.g. `1`) | list(string) | `<list>` | no |
| cluster_auth_type | Cluster authentication type. Valid values are `aws-eks-get-token` and `aws-iam-authenticator`. Amazon EKS uses the `aws eks get-token` command (available in version 1.16.232 or greater of the AWS CLI) or the AWS IAM Authenticator for Kubernetes with `kubectl` for cluster authentication. For more info, see https://docs.aws.amazon.com/en_pv/eks/latest/userguide/create-kubeconfig.html | string | `aws-eks-get-token` | no |
| delimiter | Delimiter to be used between `name`, `namespace`, `stage`, etc. | string | `-` | no |
| enabled | Whether to create the resources. Set to `false` to prevent the module from creating any resources | bool | `true` | no |
| enabled_cluster_log_types | A list of the desired control plane logging to enable. For more information, see https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. Possible values [`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`] | list(string) | `<list>` | no |
| endpoint_private_access | Indicates whether or not the Amazon EKS private API server endpoint is enabled. Default to AWS EKS resource and it is false | bool | `false` | no |
| endpoint_public_access | Indicates whether or not the Amazon EKS public API server endpoint is enabled. Default to AWS EKS resource and it is true | bool | `true` | no |
| kubernetes_version | Desired Kubernetes master version. If you do not specify a value, the latest available version is used | string | `` | no |
| map_additional_aws_accounts | Additional AWS account numbers to add to `config-map-aws-auth` ConfigMap | list(string) | `<list>` | no |
| map_additional_iam_roles | Additional IAM roles to add to `config-map-aws-auth` ConfigMap | object | `<list>` | no |
| map_additional_iam_users | Additional IAM users to add to `config-map-aws-auth` ConfigMap | object | `<list>` | no |
| name | Solution name, e.g. 'app' or 'cluster' | string | - | yes |
| namespace | Namespace, which could be your organization name, e.g. 'eg' or 'cp' | string | `` | no |
| stage | Stage, e.g. 'prod', 'staging', 'dev', or 'test' | string | `` | no |
| subnet_ids | A list of subnet IDs to launch the cluster in | list(string) | - | yes |
| tags | Additional tags (e.g. `map('BusinessUnit`,`XYZ`) | map(string) | `<map>` | no |
| vpc_id | VPC ID for the EKS cluster | string | - | yes |
| workers_role_arns | List of Role ARNs of the worker nodes | list(string) | - | yes |
| workers_security_group_count | Count of the worker Security Groups. Needed to prevent Terraform error `count can't be computed` | number | - | yes |
| workers_security_group_ids | Security Group IDs of the worker nodes | list(string) | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| config_map_data | Kubernetes ConfigMap data for worker nodes to join the EKS cluster. https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#required-kubernetes-configuration-to-join-worker-nodes |
| eks_cluster_arn | The Amazon Resource Name (ARN) of the cluster |
| eks_cluster_certificate_authority_data | The base64 encoded certificate data required to communicate with the cluster |
| eks_cluster_endpoint | The endpoint for the Kubernetes API server |
| eks_cluster_id | The name of the cluster |
| eks_cluster_version | The Kubernetes server version of the cluster |
| kubeconfig | `kubeconfig` configuration to connect to the cluster using `kubectl`. https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#configuring-kubectl-for-eks |
| security_group_arn | ARN of the EKS cluster Security Group |
| security_group_id | ID of the EKS cluster Security Group |
| security_group_name | Name of the EKS cluster Security Group |




## Share the Love 

Like this project? Please give it a ★ on [our GitHub](https://github.com/cloudposse/terraform-aws-eks-cluster)! (it helps us **a lot**) 

Are you using this project or any of our other projects? Consider [leaving a testimonial][testimonial]. =)


## Related Projects

Check out these related projects.

- [terraform-aws-eks-workers](https://github.com/cloudposse/terraform-aws-eks-workers) - Terraform module to provision an AWS AutoScaling Group, IAM Role, and Security Group for EKS Workers
- [terraform-aws-ec2-autoscale-group](https://github.com/cloudposse/terraform-aws-ec2-autoscale-group) - Terraform module to provision Auto Scaling Group and Launch Template on AWS
- [terraform-aws-ecs-container-definition](https://github.com/cloudposse/terraform-aws-ecs-container-definition) - Terraform module to generate well-formed JSON documents (container definitions) that are passed to the  aws_ecs_task_definition Terraform resource
- [terraform-aws-ecs-alb-service-task](https://github.com/cloudposse/terraform-aws-ecs-alb-service-task) - Terraform module which implements an ECS service which exposes a web service via ALB
- [terraform-aws-ecs-web-app](https://github.com/cloudposse/terraform-aws-ecs-web-app) - Terraform module that implements a web app on ECS and supports autoscaling, CI/CD, monitoring, ALB integration, and much more
- [terraform-aws-ecs-codepipeline](https://github.com/cloudposse/terraform-aws-ecs-codepipeline) - Terraform module for CI/CD with AWS Code Pipeline and Code Build for ECS
- [terraform-aws-ecs-cloudwatch-autoscaling](https://github.com/cloudposse/terraform-aws-ecs-cloudwatch-autoscaling) - Terraform module to autoscale ECS Service based on CloudWatch metrics
- [terraform-aws-ecs-cloudwatch-sns-alarms](https://github.com/cloudposse/terraform-aws-ecs-cloudwatch-sns-alarms) - Terraform module to create CloudWatch Alarms on ECS Service level metrics
- [terraform-aws-ec2-instance](https://github.com/cloudposse/terraform-aws-ec2-instance) - Terraform module for providing a general purpose EC2 instance
- [terraform-aws-ec2-instance-group](https://github.com/cloudposse/terraform-aws-ec2-instance-group) - Terraform module for provisioning multiple general purpose EC2 hosts for stateful applications



## Help

**Got a question?**

File a GitHub [issue](https://github.com/cloudposse/terraform-aws-eks-cluster/issues), send us an [email][email] or join our [Slack Community][slack].

[![README Commercial Support][readme_commercial_support_img]][readme_commercial_support_link]

## Commercial Support

Work directly with our team of DevOps experts via email, slack, and video conferencing. 

We provide [*commercial support*][commercial_support] for all of our [Open Source][github] projects. As a *Dedicated Support* customer, you have access to our team of subject matter experts at a fraction of the cost of a full-time engineer. 

[![E-Mail](https://img.shields.io/badge/email-hello@cloudposse.com-blue.svg)][email]

- **Questions.** We'll use a Shared Slack channel between your team and ours.
- **Troubleshooting.** We'll help you triage why things aren't working.
- **Code Reviews.** We'll review your Pull Requests and provide constructive feedback.
- **Bug Fixes.** We'll rapidly work to fix any bugs in our projects.
- **Build New Terraform Modules.** We'll [develop original modules][module_development] to provision infrastructure.
- **Cloud Architecture.** We'll assist with your cloud strategy and design.
- **Implementation.** We'll provide hands-on support to implement our reference architectures. 



## Terraform Module Development

Are you interested in custom Terraform module development? Submit your inquiry using [our form][module_development] today and we'll get back to you ASAP.


## Slack Community

Join our [Open Source Community][slack] on Slack. It's **FREE** for everyone! Our "SweetOps" community is where you get to talk with others who share a similar vision for how to rollout and manage infrastructure. This is the best place to talk shop, ask questions, solicit feedback, and work together as a community to build totally *sweet* infrastructure.

## Newsletter

Signup for [our newsletter][newsletter] that covers everything on our technology radar.  Receive updates on what we're up to on GitHub as well as awesome new projects we discover. 

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/cloudposse/terraform-aws-eks-cluster/issues) to report any bugs or file feature requests.

### Developing

If you are interested in being a contributor and want to get involved in developing this project or [help out](https://cpco.io/help-out) with our other projects, we would love to hear from you! Shoot us an [email][email].

In general, PRs are welcome. We follow the typical "fork-and-pull" Git workflow.

 1. **Fork** the repo on GitHub
 2. **Clone** the project to your own machine
 3. **Commit** changes to your own branch
 4. **Push** your work back up to your fork
 5. Submit a **Pull Request** so that we can review your changes

**NOTE:** Be sure to merge the latest changes from "upstream" before making a pull request!


## Copyright

Copyright © 2017-2019 [Cloud Posse, LLC](https://cpco.io/copyright)



## License 

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) 

See [LICENSE](LICENSE) for full details.

    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.









## Trademarks

All other trademarks referenced herein are the property of their respective owners.

## About

This project is maintained and funded by [Cloud Posse, LLC][website]. Like it? Please let us know by [leaving a testimonial][testimonial]!

[![Cloud Posse][logo]][website]

We're a [DevOps Professional Services][hire] company based in Los Angeles, CA. We ❤️  [Open Source Software][we_love_open_source].

We offer [paid support][commercial_support] on all of our projects.  

Check out [our other projects][github], [follow us on twitter][twitter], [apply for a job][jobs], or [hire us][hire] to help with your cloud strategy and implementation.



### Contributors

|  [![Erik Osterman][osterman_avatar]][osterman_homepage]<br/>[Erik Osterman][osterman_homepage] | [![Andriy Knysh][aknysh_avatar]][aknysh_homepage]<br/>[Andriy Knysh][aknysh_homepage] | [![Igor Rodionov][goruha_avatar]][goruha_homepage]<br/>[Igor Rodionov][goruha_homepage] |
|---|---|---|


  [osterman_homepage]: https://github.com/osterman
  [osterman_avatar]: http://s.gravatar.com/avatar/88c480d4f73b813904e00a5695a454cb?s=144


  [aknysh_homepage]: https://github.com/aknysh/
  [aknysh_avatar]: https://avatars0.githubusercontent.com/u/7356997?v=4&u=ed9ce1c9151d552d985bdf5546772e14ef7ab617&s=144


  [goruha_homepage]: https://github.com/goruha/
  [goruha_avatar]: http://s.gravatar.com/avatar/bc70834d32ed4517568a1feb0b9be7e2?s=144




[![README Footer][readme_footer_img]][readme_footer_link]
[![Beacon][beacon]][website]

  [logo]: https://cloudposse.com/logo-300x69.svg
  [docs]: https://cpco.io/docs
  [website]: https://cpco.io/homepage
  [github]: https://cpco.io/github
  [jobs]: https://cpco.io/jobs
  [hire]: https://cpco.io/hire
  [slack]: https://cpco.io/slack
  [linkedin]: https://cpco.io/linkedin
  [twitter]: https://cpco.io/twitter
  [testimonial]: https://cpco.io/leave-testimonial
  [newsletter]: https://cpco.io/newsletter
  [email]: https://cpco.io/email
  [commercial_support]: https://cpco.io/commercial-support
  [we_love_open_source]: https://cpco.io/we-love-open-source
  [module_development]: https://cpco.io/module-development
  [terraform_modules]: https://cpco.io/terraform-modules
  [readme_header_img]: https://cloudposse.com/readme/header/img?repo=cloudposse/terraform-aws-eks-cluster
  [readme_header_link]: https://cloudposse.com/readme/header/link?repo=cloudposse/terraform-aws-eks-cluster
  [readme_footer_img]: https://cloudposse.com/readme/footer/img?repo=cloudposse/terraform-aws-eks-cluster
  [readme_footer_link]: https://cloudposse.com/readme/footer/link?repo=cloudposse/terraform-aws-eks-cluster
  [readme_commercial_support_img]: https://cloudposse.com/readme/commercial-support/img?repo=cloudposse/terraform-aws-eks-cluster
  [readme_commercial_support_link]: https://cloudposse.com/readme/commercial-support/link?repo=cloudposse/terraform-aws-eks-cluster
  [share_twitter]: https://twitter.com/intent/tweet/?text=terraform-aws-eks-cluster&url=https://github.com/cloudposse/terraform-aws-eks-cluster
  [share_linkedin]: https://www.linkedin.com/shareArticle?mini=true&title=terraform-aws-eks-cluster&url=https://github.com/cloudposse/terraform-aws-eks-cluster
  [share_reddit]: https://reddit.com/submit/?url=https://github.com/cloudposse/terraform-aws-eks-cluster
  [share_facebook]: https://facebook.com/sharer/sharer.php?u=https://github.com/cloudposse/terraform-aws-eks-cluster
  [share_googleplus]: https://plus.google.com/share?url=https://github.com/cloudposse/terraform-aws-eks-cluster
  [share_email]: mailto:?subject=terraform-aws-eks-cluster&body=https://github.com/cloudposse/terraform-aws-eks-cluster
  [beacon]: https://ga-beacon.cloudposse.com/UA-76589703-4/cloudposse/terraform-aws-eks-cluster?pixel&cs=github&cm=readme&an=terraform-aws-eks-cluster
