resource "dodopayments_webhook" "billing" {
  url          = var.webhook_url
  description  = "${local.name_prefix}Billing events for the AI platform"
  filter_types = local.billing_events

  # If someone disables the webhook in the dashboard, the drift run reports it and the next apply enables it again.
  disabled = false

  headers = {
    "X-Catalog" = "terraform-dodopayments-example"
  }

  metadata = {
    managed_by = "terraform"
  }
}

# Terraform reads the signing secret on each run. The secret is not in the plan or the state.
ephemeral "dodopayments_webhook_secret" "billing" {
  webhook_id = dodopayments_webhook.billing.id
}

# The webhook receiver reads the secret from Secret Manager.
resource "google_secret_manager_secret" "webhook_signing" {
  count = var.gcp_project_id == null ? 0 : 1

  secret_id = "${var.resource_prefix == "" ? "" : "${var.resource_prefix}-"}dodo-webhook-signing-secret"

  replication {
    auto {}
  }

  labels = {
    managed_by = "terraform"
  }
}

resource "google_secret_manager_secret_version" "webhook_signing" {
  count = var.gcp_project_id == null ? 0 : 1

  secret                 = google_secret_manager_secret.webhook_signing[0].id
  secret_data_wo         = ephemeral.dodopayments_webhook_secret.billing.secret
  secret_data_wo_version = 1

  # A new webhook has a new secret, so write a new version.
  lifecycle {
    replace_triggered_by = [dodopayments_webhook.billing.id]
  }
}
