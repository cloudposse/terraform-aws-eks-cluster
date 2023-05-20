region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

namespace = "eg"

stage = "test"

name = "eks"

# oidc_provider_enabled is required to be true for VPC CNI addon
oidc_provider_enabled = true

enabled_cluster_log_types = ["audit"]

cluster_log_retention_period = 7

instance_types = ["t3.small"]

desired_size = 2

max_size = 3

min_size = 2

kubernetes_labels = {}

cluster_encryption_config_enabled = true

# When updating the Kubernetes version, also update the API and client-go version in test/src/go.mod
kubernetes_version = "1.26"

addons = [
  // https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html#vpc-cni-latest-available-version
  {
    addon_name               = "vpc-cni"
    addon_version            = null
    resolve_conflicts        = "NONE"
    service_account_role_arn = null
  },
  // https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html
  {
    addon_name               = "kube-proxy"
    addon_version            = null
    resolve_conflicts        = "NONE"
    service_account_role_arn = null
  },
  // https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
  {
    addon_name               = "coredns"
    addon_version            = null
    resolve_conflicts        = "NONE"
    service_account_role_arn = null
  },
]
