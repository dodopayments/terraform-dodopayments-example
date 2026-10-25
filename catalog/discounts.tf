# 20% off the first year of an annual plan, until the launch ends. The discount stays on a plan change.
resource "dodopayments_discount" "launch" {
  name   = "${local.name_prefix}Launch: 20% off annual plans"
  code   = "${var.discount_code_prefix}LAUNCH20"
  type   = "percentage"
  amount = 2000 # basis points

  restricted_to            = [for tier in local.tier_order : dodopayments_product.plan["${tier}_annual"].id]
  expires_at               = var.launch_promo_ends_at
  subscription_cycles      = 1
  usage_limit              = 1000
  per_customer_usage_limit = 1
  preserve_on_plan_change  = true

  metadata = {
    campaign = "launch"
  }
}

# 50% off monthly Starter and Pro for 12 months, for new customers only, capped at $25 a month.
resource "dodopayments_discount" "student" {
  name   = "${local.name_prefix}Students: 50% off for a year"
  code   = "${var.discount_code_prefix}STUDENT50"
  type   = "percentage"
  amount = 5000

  restricted_to        = [dodopayments_product.plan["starter_monthly"].id, dodopayments_product.plan["pro_monthly"].id]
  customer_eligibility = "first_time"
  subscription_cycles  = 12

  currency_options = [
    { currency = "USD", is_default = true, max_amount_possible = 2500 },
  ]
}

# $10 off a credit pack of $39 or more, with a fixed amount in each currency.
resource "dodopayments_discount" "welcome" {
  name   = "${local.name_prefix}Welcome: $10 off a credit pack"
  code   = "${var.discount_code_prefix}WELCOME10"
  type   = "flat"
  amount = 1000

  restricted_to = [for k in ["medium", "large"] : dodopayments_product.credit_pack[k].id]

  currency_options = [
    { currency = "USD", is_default = true, max_amount_possible = 1000, minimum_subtotal = 3900 },
    { currency = "EUR", max_amount_possible = 900, minimum_subtotal = 3500 },
    { currency = "INR", max_amount_possible = 80000, minimum_subtotal = 300000 },
  ]
}
