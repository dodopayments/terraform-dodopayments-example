output "plan_product_ids" {
  description = "Subscription product ID for each plan, keyed `<tier>_<cycle>`."
  value       = { for k, p in dodopayments_product.plan : k => p.id }
}

output "enterprise_product_id" {
  value = dodopayments_product.enterprise.id
}

output "credit_pack_product_ids" {
  value = { for k, p in dodopayments_product.credit_pack : k => p.id }
}

output "sponsor_product_id" {
  value = dodopayments_product.sponsor.id
}

output "addon_ids" {
  value = { for k, a in dodopayments_addon.this : k => a.id }
}

output "plan_collection_id" {
  description = "Use it as product_collection_id in POST /checkouts to show the plan picker."
  value       = dodopayments_product_collection.plans.id
}

output "discount_codes" {
  value = {
    launch  = dodopayments_discount.launch.code
    student = dodopayments_discount.student.code
    welcome = dodopayments_discount.welcome.code
  }
}

output "meter_event_names" {
  description = "The event_name to send to POST /events for each meter."
  value       = { for k, m in dodopayments_meter.this : k => m.event_name }
}

output "feature_ids" {
  description = "The feature_id to test in the application for each feature flag."
  value       = { for k, e in dodopayments_entitlement.feature : k => e.integration_config.feature_id }
}

output "webhook_id" {
  value = dodopayments_webhook.billing.id
}

output "webhook_secret_id" {
  description = "The Secret Manager secret that holds the webhook signing secret."
  value       = one(google_secret_manager_secret.webhook_signing[*].secret_id)
}
