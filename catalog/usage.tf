resource "dodopayments_meter" "this" {
  for_each = local.meters

  name             = "${local.name_prefix}${each.value.name}"
  description      = each.value.description
  event_name       = "${local.event_prefix}${each.value.event_name}"
  measurement_unit = each.value.unit
  aggregation      = each.value.aggregation

  filter = each.value.filter == null ? null : {
    conjunction = each.value.filter.conjunction
    clauses     = jsonencode(each.value.filter.clauses)
  }
}

# One credit balance for all AI usage. Plans grant credits each cycle and packs top it up.
resource "dodopayments_credit_entitlement" "ai_credits" {
  name        = "${local.name_prefix}AI credits"
  description = "Shared balance for completions. 1 credit = 1,000 LLM tokens."
  unit        = "credits"
  precision   = 0

  currency       = "USD"
  price_per_unit = "1.5"

  expires_after_days = 90

  rollover_enabled            = true
  rollover_percentage         = 50
  max_rollover_count          = 2
  rollover_timeframe_count    = 1
  rollover_timeframe_interval = "Month"

  overage_enabled  = true
  overage_behavior = "invoice_at_billing"
  overage_limit    = 250000
}

resource "dodopayments_entitlement" "feature" {
  for_each = local.features

  name             = "${local.name_prefix}${each.value}"
  integration_type = "feature_flag"
  integration_config = {
    feature_id   = "${local.key_prefix}${each.key}"
    feature_type = "boolean"
  }
  metadata = {
    managed_by = "terraform"
  }
}

resource "dodopayments_addon" "this" {
  for_each = local.addons

  name         = "${local.name_prefix}${each.value.name}"
  description  = each.value.description
  currency     = "USD"
  price        = each.value.price
  tax_category = "saas"
}
