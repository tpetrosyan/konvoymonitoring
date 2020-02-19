data "aws_region" "current" {}

locals {
  ec2_service_principal = "${substr(data.aws_region.current.name, 0, 3) == "cn-" ? "ec2.amazonaws.com.cn" : "ec2.amazonaws.com"}"
  node_policy_name      = "${local.cluster_name}-tig-node-policy"
  node_role_name        = "${local.cluster_name}-tig-node-role"
  node_profile_name     = "${local.cluster_name}-tig-node-profile"
  s3_bucket_name        = "k8slab-thanos-tig-metrics"
}
