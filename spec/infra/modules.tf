module "infrastructure_events" {
  source = "../../../src"

  region = "${var.region}"
  deployment_identifier = "${var.deployment_identifier}"

  bucket_name_prefix = "${var.bucket_name_prefix}"
  topic_name_prefix = "${var.topic_name_prefix}"
}
