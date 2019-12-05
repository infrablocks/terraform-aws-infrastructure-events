locals {
  bucket_name = "${var.bucket_name_prefix}-${var.region}-${var.deployment_identifier}"
  bucket_arn = "arn:aws:s3:::${local.bucket_name}"
}

data "aws_iam_policy_document" "infrastructure_events" {
  statement {
    sid = "AllowEverythingForOwningAccount"

    effect = "Allow"

    resources = [
      "${local.bucket_arn}/*"
    ]

    actions = [
      "s3:*"
    ]

    principals {
      identifiers = [local.current_account_id]
      type = "AWS"
    }
  }
  statement {
    sid = "AllowGetAndPutFromTrustedAccounts"

    effect = "Allow"

    resources = [
      "${local.bucket_arn}/*"
    ]

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObjectVersion",
      "s3:DeleteObjectVersion",
      "s3:GetObjectAcl",
      "s3:PutObjectAcl",
      "s3:GetObjectVersionAcl",
      "s3:PutObjectVersionAcl",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
      "s3:DeleteObjectTagging",
      "s3:GetObjectVersionTagging",
      "s3:PutObjectVersionTagging",
      "s3:DeleteObjectVersionTagging"
    ]

    principals {
      identifiers = var.trusted_principals
      type = "AWS"
    }
  }
}

resource "aws_s3_bucket" "infrastructure_events" {
  bucket = local.bucket_name
  region = var.region

  policy = data.aws_iam_policy_document.infrastructure_events.json

  tags = {
    Name = local.bucket_name
    Component = "common"
    DeploymentIdentifier = var.deployment_identifier
  }
}

resource "aws_s3_bucket_notification" "vpc_lifecycle_notifications" {
  bucket = aws_s3_bucket.infrastructure_events.bucket

  depends_on = [
    aws_sns_topic_policy.infrastructure_events
  ]

  topic {
    topic_arn = aws_sns_topic.infrastructure_events.arn

    events = [
      "s3:ObjectCreated:*",
      "s3:ObjectRemoved:*"
    ]
  }
}
