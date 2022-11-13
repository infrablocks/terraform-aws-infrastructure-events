variable "region" {}
variable "deployment_identifier" {}

variable "bucket_name_prefix" {}
variable "topic_name_prefix" {}

variable "trusted_principals" {
  type = list(string)
}
