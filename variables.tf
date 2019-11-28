variable "region" {
  type = string
  description = "The region into which to deploy the VPC."
}

variable "deployment_identifier" {
  type = string
  description = "An identifier for this instantiation."
}

variable "bucket_name_prefix" {
  type = string
  description = "The prefix to use for the name of the created S3 bucket."
}
variable "topic_name_prefix" {
  type = string
  description = "The prefix to use for the name of the created topic."
}

variable "trusted_principals" {
  type = list(string)
  default = []
  description = "The account IDs or IAM identity ARNs of principals that are trusted to manage objects in the bucket. Defaults to the owning account."
}
