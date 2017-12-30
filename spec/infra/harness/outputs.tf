output "infrastructure_events_bucket" {
  value = "${module.infrastructure_events.infrastructure_events_bucket}"
}

output "infrastructure_events_topic_arn" {
  value = "${module.infrastructure_events.infrastructure_events_topic_arn}"
}
