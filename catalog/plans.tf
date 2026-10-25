resource "dodopayments_product" "plan" {
  for_each = local.plans

  name         = "${local.name_prefix}${each.value.title} (${each.value.label})"
  description  = "${each.value.title} plan, billed ${lower(each.value.label)}. Includes ${each.value.credits} AI credits each cycle."
  tax_category = "saas"
  pricing_mode = contains(keys(local.localized), each.key) ? "by_currency" : null

  price = {
    type                         = "recurring_price"
    currency                     = "USD"
    price                        = each.value.price
    tax_inclusive                = false
    payment_frequency_count      = 1
    payment_frequency_interval   = each.value.interval
    subscription_period_count    = 20
    subscription_period_interval = "Year"
    purchasing_power_parity      = each.value.ppp

    trial_period_days             = each.value.trial_days
    trial_payment_method_optional = each.value.trial_days > 0 ? true : null
  }

  credit_entitlements = [{
    credit_entitlement_id         = dodopayments_credit_entitlement.ai_credits.id
    credits_amount                = tostring(each.value.credits)
    low_balance_threshold_percent = 20
    trial_credits                 = each.value.trial_days > 0 ? "500" : null
    # An annual plan grants 12 months of credits at the start of the year, so they must last the year.
    expires_after_days = each.value.cycle == "annual" ? 365 : 90
  }]

  entitlements = [for f in each.value.features : { entitlement_id = dodopayments_entitlement.feature[f].id }]
  addons       = [for a in each.value.addons : dodopayments_addon.this[a].id]

  metadata = {
    tier       = each.value.tier
    cycle      = each.value.cycle
    managed_by = "terraform"
  }

  lifecycle {
    precondition {
      condition     = each.value.cycle == "monthly" || each.value.price <= floor(each.value.monthly * 12 * 0.9)
      error_message = "The ${each.value.title} annual price (${each.value.price}) must save at least 10% on 12 monthly payments (${each.value.monthly * 12})."
    }
  }
}

resource "dodopayments_product_localized_price" "this" {
  for_each = local.localized_prices

  product_id = dodopayments_product.plan[each.value.plan].id
  currency   = each.value.currency
  amount     = each.value.amount
}

# Enterprise: a platform fee, metered requests and storage in money, and tokens from the credit balance.
resource "dodopayments_product" "enterprise" {
  name         = "${local.name_prefix}Enterprise (usage-based)"
  description  = "A platform fee plus usage. 1M requests and 100 GB are free each month."
  tax_category = "saas"

  price = {
    type                         = "usage_based_price"
    currency                     = "USD"
    fixed_price                  = 49900
    tax_inclusive                = false
    payment_frequency_count      = 1
    payment_frequency_interval   = "Month"
    subscription_period_count    = 20
    subscription_period_interval = "Year"

    meters = [
      {
        meter_id       = dodopayments_meter.this["api_requests"].id
        price_per_unit = "0.02"
        free_threshold = 1000000
      },
      {
        meter_id       = dodopayments_meter.this["storage"].id
        price_per_unit = "25"
        free_threshold = 100
      },
      {
        meter_id               = dodopayments_meter.this["llm_tokens"].id
        credit_entitlement_id  = dodopayments_credit_entitlement.ai_credits.id
        meter_units_per_credit = "1000"
      },
    ]
  }

  credit_entitlements = [{
    credit_entitlement_id         = dodopayments_credit_entitlement.ai_credits.id
    credits_amount                = "250000"
    low_balance_threshold_percent = 10
  }]

  entitlements = [for f in keys(local.features) : { entitlement_id = dodopayments_entitlement.feature[f].id }]
  addons       = [dodopayments_addon.this["priority_support"].id]

  metadata = {
    tier       = "enterprise"
    managed_by = "terraform"
  }
}
