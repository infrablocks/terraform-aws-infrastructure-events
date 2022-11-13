locals {
  # default for cases when `null` value provided, meaning "use default"
  trusted_principals = var.trusted_principals == null ? [] : var.trusted_principals
}
