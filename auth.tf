# The EKS service does not provide a cluster-level API parameter or resource to automatically configure the underlying Kubernetes cluster
# to allow worker nodes to join the cluster via AWS IAM role authentication.

# NOTE: To automatically apply the Kubernetes configuration to the cluster (which allows the worker nodes to join the cluster),
# the requirements outlined here must be met:
# https://learn.hashicorp.com/terraform/aws/eks-intro#preparation
# https://learn.hashicorp.com/terraform/aws/eks-intro#configuring-kubectl-for-eks
# https://learn.hashicorp.com/terraform/aws/eks-intro#required-kubernetes-configuration-to-join-worker-nodes

# Additional links
# https://learn.hashicorp.com/terraform/aws/eks-intro
# https://itnext.io/how-does-client-authentication-work-on-amazon-eks-c4f2b90d943b
# https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html
# https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
# https://docs.aws.amazon.com/cli/latest/reference/eks/update-kubeconfig.html
# https://docs.aws.amazon.com/en_pv/eks/latest/userguide/create-kubeconfig.html
# https://itnext.io/kubernetes-authorization-via-open-policy-agent-a9455d9d5ceb
# http://marcinkaszynski.com/2018/07/12/eks-auth.html
# https://cloud.google.com/kubernetes-engine/docs/concepts/configmap
# http://yaml-multiline.info
# https://github.com/terraform-providers/terraform-provider-kubernetes/issues/216
# https://www.terraform.io/docs/cloud/run/install-software.html
# https://stackoverflow.com/questions/26123740/is-it-possible-to-install-aws-cli-package-without-root-permission
# https://stackoverflow.com/questions/58232731/kubectl-missing-form-terraform-cloud
# https://docs.aws.amazon.com/cli/latest/userguide/install-bundle.html
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv1.html


locals {
  certificate_authority_data_list          = coalescelist(aws_eks_cluster.default.*.certificate_authority, [[{ data : "" }]])
  certificate_authority_data_list_internal = local.certificate_authority_data_list[0]
  certificate_authority_data_map           = local.certificate_authority_data_list_internal[0]
  certificate_authority_data               = local.certificate_authority_data_map["data"]

  configmap_auth_template_file = var.configmap_auth_template_file == "" ? join("/", [path.module, "configmap-auth.yaml.tpl"]) : var.configmap_auth_template_file
  configmap_auth_file          = var.configmap_auth_file == "" ? join("/", [path.module, "configmap-auth.yaml"]) : var.configmap_auth_file

  external_packages_install_path = var.external_packages_install_path == "" ? join("/", [path.module, ".terraform/bin"]) : var.external_packages_install_path
  kubectl_version                = var.kubectl_version == "" ? "$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)" : var.kubectl_version

  cluster_name = join("", aws_eks_cluster.default.*.id)

  # Add worker nodes role ARNs (could be from many worker groups) to the ConfigMap
  map_worker_roles = [
    for role_arn in var.workers_role_arns : {
      rolearn : role_arn
      username : "system:node:{{EC2PrivateDNSName}}"
      groups : [
        "system:bootstrappers",
        "system:nodes"
      ]
    }
  ]

  map_worker_roles_yaml            = trimspace(yamlencode(local.map_worker_roles))
  map_additional_iam_roles_yaml    = trimspace(yamlencode(var.map_additional_iam_roles))
  map_additional_iam_users_yaml    = trimspace(yamlencode(var.map_additional_iam_users))
  map_additional_aws_accounts_yaml = trimspace(yamlencode(var.map_additional_aws_accounts))
}

data "template_file" "configmap_auth" {
  count    = var.enabled && var.apply_config_map_aws_auth ? 1 : 0
  template = file(local.configmap_auth_template_file)

  vars = {
    map_worker_roles_yaml            = local.map_worker_roles_yaml
    map_additional_iam_roles_yaml    = local.map_additional_iam_roles_yaml
    map_additional_iam_users_yaml    = local.map_additional_iam_users_yaml
    map_additional_aws_accounts_yaml = local.map_additional_aws_accounts_yaml
  }
}

resource "local_file" "configmap_auth" {
  count    = var.enabled && var.apply_config_map_aws_auth ? 1 : 0
  content  = join("", data.template_file.configmap_auth.*.rendered)
  filename = local.configmap_auth_file
}

resource "null_resource" "apply_configmap_auth" {
  count = var.enabled && var.apply_config_map_aws_auth ? 1 : 0

  triggers = {
    cluster_updated                 = join("", aws_eks_cluster.default.*.id)
    worker_roles_updated            = local.map_worker_roles_yaml
    additional_roles_updated        = local.map_additional_iam_roles_yaml
    additional_users_updated        = local.map_additional_iam_users_yaml
    additional_aws_accounts_updated = local.map_additional_aws_accounts_yaml
  }

  depends_on = [aws_eks_cluster.default, local_file.configmap_auth]

  provisioner "local-exec" {
    interpreter = [var.local_exec_interpreter, "-c"]

    command = <<EOT
      install_aws_cli=${var.install_aws_cli}
      if [[ "$install_aws_cli" = true ]] ; then
          echo 'Installing AWS CLI...'
          mkdir -p ${local.external_packages_install_path}
          cd ${local.external_packages_install_path}
          curl -LO https://s3.amazonaws.com/aws-cli/awscli-bundle.zip
          unzip ./awscli-bundle.zip
          ./awscli-bundle/install -i ${local.external_packages_install_path}
          export PATH=$PATH:${local.external_packages_install_path}
          echo 'Installed AWS CLI'
          which aws
          aws --version
      fi

      install_kubectl=${var.install_kubectl}
      if [[ "$install_kubectl" = true ]] ; then
          echo 'Installing kubectl...'
          mkdir -p ${local.external_packages_install_path}
          cd ${local.external_packages_install_path}
          curl -LO https://storage.googleapis.com/kubernetes-release/release/${local.kubectl_version}/bin/linux/amd64/kubectl
          chmod +x ./kubectl
          export PATH=$PATH:${local.external_packages_install_path}
          echo 'Installed kubectl'
          which kubectl
          kubectl version
      fi

      echo 'Applying ConfigMap...'
      aws eks update-kubeconfig --name=${local.cluster_name} --region=${var.region} --kubeconfig=${var.kubeconfig_path}
      kubectl apply -f ${local.configmap_auth_file} --kubeconfig ${var.kubeconfig_path}
      echo 'Applied ConfigMap'
    EOT
  }
}
