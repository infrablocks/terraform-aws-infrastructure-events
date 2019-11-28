

locals {
  topic_name = "${var.topic_name_prefix}-${var.region}-${var.deployment_identifier}"
}

data "aws_iam_policy_document" "infrastructure_events_topic" {
 statement {
   actions = ["SNS:Publish"]

   effect = "Allow"

   resources = [
     "arn:aws:sns:${var.region}:${local.current_account_id}:${local.topic_name}"
   ]

   condition {
     test = "ArnLike"
     values = ["arn:aws:s3:::${local.bucket_name}"]
     variable = "aws:SourceArn"
   }

   principals {
     identifiers = ["s3.amazonaws.com"]
     type = "Service"
   }
 }
}

resource "aws_sns_topic" "infrastructure_events" {
  name = local.topic_name
  display_name = local.topic_name
}

resource "aws_sns_topic_policy" "infrastructure_events" {
  arn = aws_sns_topic.infrastructure_events.arn
  policy = data.aws_iam_policy_document.infrastructure_events_topic.json
}
