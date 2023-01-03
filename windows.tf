resource "kubernetes_config_map" "aws_amazon_vpc_cni" {
  count      = local.enabled && var.windows_support ? 1 : 0
  depends_on = [null_resource.wait_for_cluster]

  metadata {
    name      = "amazon-vpc-cni"
    namespace = "kube-system"
  }

  data = {
    enable-windows-ipam    = "true"
  }

}