module "infrastructure_events" {
  # This makes absolutely no sense. I think there's a bug in terraform.
  source = "./../../../../../../../"

  region = var.region
  deployment_identifier = var.deployment_identifier

  bucket_name_prefix = var.bucket_name_prefix
  topic_name_prefix = var.topic_name_prefix

  trusted_principals = var.trusted_principals
}
