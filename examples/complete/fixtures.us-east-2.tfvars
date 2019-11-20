region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

namespace = "eg"

stage = "test"

name = "eks"

instance_type = "t2.small"

health_check_type = "EC2"

wait_for_capacity_timeout = "10m"

max_size = 3

min_size = 2

autoscaling_policies_enabled = true

cpu_utilization_high_threshold_percent = 80

cpu_utilization_low_threshold_percent = 20

associate_public_ip_address = true

kubernetes_version = "1.14"

kubeconfig_path = "/.kube/config"

oidc_provider_enabled = true

enabled_cluster_log_types = ["audit"]

cluster_log_retention_period = 7
