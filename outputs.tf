output "infrastructure_events_bucket" {
  value = aws_s3_bucket.infrastructure_events.bucket
}

output "infrastructure_events_topic_arn" {
  value = aws_sns_topic.infrastructure_events.arn
}
