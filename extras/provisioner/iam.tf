# Define IAM role to create external volumes on AWS
resource "aws_iam_instance_profile" "node_profile" {
  name  = "${local.node_profile_name}"
  role  = "${aws_iam_role.node_role.name}"
  count = "${var.create_iam_instance_profile ? 1 : 0}"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_iam_role_policy" "agent_policy" {
  name  = "${local.node_policy_name}"
  role  = "${aws_iam_role.node_role.id}"
  count = "${var.create_iam_instance_profile ? 1 : 0}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:CopySnapshot",
                "elasticloadbalancing:DetachLoadBalancerFromSubnets",
                "s3:GetAccessPoint",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:DeleteSnapshot",
                "ec2:DescribeInstances",
                "ec2:DeleteTags",
                "elasticloadbalancing:ConfigureHealthCheck",
                "ec2:DescribeSnapshots",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:DescribeLoadBalancers",
                "ec2:DeleteVolume",
                "ec2:DescribeVolumeStatus",
                "ec2:CreateRoute",
                "ec2:CreateSecurityGroup",
                "ec2:DescribeVolumes",
                "ec2:CreateSnapshot",
                "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
                "s3:HeadBucket",
                "ec2:ModifyInstanceAttribute",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:CreateLoadBalancerPolicy",
                "ec2:DescribeRouteTables",
                "ec2:DetachVolume",
                "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:AttachLoadBalancerToSubnets",
                "s3:ListAccessPoints",
                "ec2:DescribeSnapshotAttribute",
                "ec2:DescribeTags",
                "ec2:CreateTags",
                "s3:ListJobs",
                "ec2:DeleteRoute",
                "elasticloadbalancing:CreateLoadBalancerListeners",
                "ec2:DescribeVolumeAttribute",
                "ec2:DescribeSecurityGroups",
                "ec2:CreateVolume",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "ec2:RevokeSecurityGroupIngress",
                "s3:GetAccountPublicAccessBlock",
                "s3:ListAllMyBuckets",
                "ec2:DeleteSecurityGroup",
                "elasticloadbalancing:DeleteLoadBalancerListeners",
                "s3:CreateJob",
                "ec2:DescribeSubnets",
                "elasticloadbalancing:ModifyLoadBalancerAttributes"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:PutAnalyticsConfiguration",
                "s3:GetObjectVersionTagging",
                "s3:CreateBucket",
                "s3:ReplicateObject",
                "s3:GetObjectAcl",
                "s3:GetBucketObjectLockConfiguration",
                "s3:PutLifecycleConfiguration",
                "s3:GetObjectVersionAcl",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "s3:DeleteObjectTagging",
                "s3:GetBucketPolicyStatus",
                "s3:GetObjectRetention",
                "s3:GetBucketWebsite",
                "s3:PutReplicationConfiguration",
                "s3:DeleteObjectVersionTagging",
                "s3:PutObjectLegalHold",
                "s3:GetObjectLegalHold",
                "s3:GetBucketNotification",
                "s3:PutBucketCORS",
                "s3:GetReplicationConfiguration",
                "s3:ListMultipartUploadParts",
                "s3:PutObject",
                "s3:GetObject",
                "s3:PutBucketNotification",
                "s3:DescribeJob",
                "s3:PutBucketLogging",
                "s3:PutBucketObjectLockConfiguration",
                "s3:GetObjectVersionForReplication",
                "s3:GetLifecycleConfiguration",
                "s3:GetInventoryConfiguration",
                "s3:GetBucketTagging",
                "s3:PutAccelerateConfiguration",
                "s3:DeleteObjectVersion",
                "s3:GetBucketLogging",
                "s3:ListBucketVersions",
                "s3:ReplicateTags",
                "s3:RestoreObject",
                "s3:ListBucket",
                "s3:GetAccelerateConfiguration",
                "s3:GetBucketPolicy",
                "s3:PutEncryptionConfiguration",
                "s3:GetEncryptionConfiguration",
                "s3:GetObjectVersionTorrent",
                "s3:AbortMultipartUpload",
                "s3:PutBucketTagging",
                "s3:GetBucketRequestPayment",
                "s3:UpdateJobPriority",
                "s3:GetObjectTagging",
                "s3:GetMetricsConfiguration",
                "s3:DeleteBucket",
                "s3:PutBucketVersioning",
                "s3:GetBucketPublicAccessBlock",
                "s3:ListBucketMultipartUploads",
                "s3:PutMetricsConfiguration",
                "s3:PutObjectVersionTagging",
                "s3:UpdateJobStatus",
                "s3:GetBucketVersioning",
                "s3:GetBucketAcl",
                "s3:PutInventoryConfiguration",
                "s3:GetObjectTorrent",
                "s3:PutBucketRequestPayment",
                "s3:PutObjectRetention",
                "s3:ReplicateDelete",
                "s3:GetObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::*/*",
                "arn:aws:s3:*:*:job/*",
                "arn:aws:s3:::${local.s3_bucket_name}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "node_role" {
  name  = "${local.node_role_name}"
  count = "${var.create_iam_instance_profile ? 1 : 0}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "${local.ec2_service_principal}"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
