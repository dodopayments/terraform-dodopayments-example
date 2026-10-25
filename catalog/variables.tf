variable "dodo_environment" {
  description = "The Dodo Payments environment: `test_mode` or `live_mode`."
  type        = string
  default     = "test_mode"

  validation {
    condition     = contains(["test_mode", "live_mode"], var.dodo_environment)
    error_message = "The value must be test_mode or live_mode."
  }
}

variable "resource_prefix" {
  description = "Prefix for the name of each catalog object. The nightly e2e run sets it, so that its objects do not collide with the live catalog."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^([a-z0-9][a-z0-9-]{0,22}[a-z0-9])?$", var.resource_prefix))
    error_message = "Use 0-24 lowercase letters, digits or hyphens. Do not start or end with a hyphen."
  }
}

variable "discount_code_prefix" {
  description = "Prefix for each discount code. A discount code has a maximum of 16 characters, and the longest code in this catalog has 9."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[A-Z0-9]{0,7}$", var.discount_code_prefix))
    error_message = "Use 0-7 uppercase letters or digits."
  }
}

variable "launch_promo_ends_at" {
  description = "The end of the launch promotion (RFC 3339). A check warns 30 days before this time."
  type        = string
  default     = "2027-06-30T23:59:59Z"

  validation {
    condition     = can(timeadd(var.launch_promo_ends_at, "0s"))
    error_message = "Use an RFC 3339 timestamp, for example 2027-06-30T23:59:59Z."
  }
}

variable "webhook_url" {
  description = "The HTTPS endpoint that receives the billing events."
  type        = string
  default     = "https://example.com/webhooks/dodo"

  validation {
    condition     = startswith(var.webhook_url, "https://")
    error_message = "The webhook URL must use HTTPS."
  }
}

variable "gcp_project_id" {
  description = "The GCP project that keeps the webhook signing secret in Secret Manager. Set it to null to skip Secret Manager."
  type        = string
  default     = "dodopayments-tf-example"
}
