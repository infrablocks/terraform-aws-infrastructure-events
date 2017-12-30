resource "aws_s3_bucket" "infrastructure_events" {
  bucket = "${var.bucket_name_prefix}-${var.region}-${var.deployment_identifier}"
  region = "${var.region}"

  tags {
    Name = "${var.bucket_name_prefix}-${var.region}-${var.deployment_identifier}",
    Component = "common"
    DeploymentIdentifier = "${var.deployment_identifier}"
  }
}

resource "aws_s3_bucket_notification" "vpc_lifecycle_notifications" {
  bucket = "${aws_s3_bucket.infrastructure_events.bucket}"

  depends_on = ["aws_sns_topic_policy.infrastructure_events"]

  topic {
    topic_arn = "${aws_sns_topic.infrastructure_events.arn}"

    events = [
      "s3:ObjectCreated:*",
      "s3:ObjectRemoved:*"
    ]
  }
}
