# The pricing model, as data. Change a number here and the plan shows every object that moves.

locals {
  name_prefix  = var.resource_prefix == "" ? "" : "[${var.resource_prefix}] "
  key_prefix   = var.resource_prefix == "" ? "" : "${replace(var.resource_prefix, "-", "_")}_"
  event_prefix = var.resource_prefix == "" ? "" : "${var.resource_prefix}."

  # Usage that the application reports with POST /events.
  meters = {
    api_requests = {
      name        = "API requests"
      description = "Successful API calls. Calls that fail with a server error are free."
      event_name  = "api.request"
      aggregation = { type = "count", key = null }
      unit        = "requests"
      filter = {
        conjunction = "and"
        clauses     = [{ key = "status", operator = "less_than", value = 500 }]
      }
    }
    llm_tokens = {
      name        = "LLM tokens"
      description = "Input and output tokens of each completion."
      event_name  = "llm.completion"
      aggregation = { type = "sum", key = "tokens" }
      unit        = "tokens"
      filter      = null
    }
    storage = {
      name        = "Vector storage"
      description = "The largest vector index size in the billing period."
      event_name  = "storage.snapshot"
      aggregation = { type = "max", key = "gb" }
      unit        = "GB"
      filter      = null
    }
  }

  # Boolean feature flags. Each tier unlocks a set of them.
  features = {
    api_access      = "API access"
    team_workspaces = "Team workspaces"
    sso             = "SAML single sign-on"
    audit_logs      = "Audit logs"
    dedicated_infra = "Dedicated inference capacity"
  }

  addons = {
    extra_seat = {
      name        = "Extra seat"
      description = "One more team member on the workspace."
      price       = 1500
    }
    priority_support = {
      name        = "Priority support"
      description = "A 4-hour first response time, every day."
      price       = 9900
    }
  }

  # Prices are in cents. An annual price must save at least 10% (see the precondition in plans.tf).
  tiers = {
    starter = {
      title      = "Starter"
      monthly    = 1900
      annual     = 19000
      credits    = 1000
      trial_days = 0
      ppp        = true
      features   = ["api_access"]
      addons     = ["extra_seat"]
    }
    pro = {
      title      = "Pro"
      monthly    = 4900
      annual     = 49000
      credits    = 10000
      trial_days = 14
      ppp        = false
      features   = ["api_access", "team_workspaces"]
      addons     = ["extra_seat", "priority_support"]
    }
    scale = {
      title      = "Scale"
      monthly    = 14900
      annual     = 149000
      credits    = 50000
      trial_days = 14
      ppp        = false
      features   = ["api_access", "team_workspaces", "sso", "audit_logs"]
      addons     = ["extra_seat", "priority_support"]
    }
  }

  tier_order = ["starter", "pro", "scale"]

  billing_cycles = {
    monthly = { interval = "Month", label = "Monthly", credit_multiplier = 1 }
    annual  = { interval = "Year", label = "Annual", credit_multiplier = 12 }
  }

  # 3 tiers x 2 billing cycles = 6 subscription products, keyed "pro_annual" and so on.
  plans = {
    for pair in setproduct(keys(local.tiers), keys(local.billing_cycles)) :
    "${pair[0]}_${pair[1]}" => merge(local.tiers[pair[0]], {
      tier     = pair[0]
      cycle    = pair[1]
      interval = local.billing_cycles[pair[1]].interval
      label    = local.billing_cycles[pair[1]].label
      price    = pair[1] == "monthly" ? local.tiers[pair[0]].monthly : local.tiers[pair[0]].annual
      credits  = local.tiers[pair[0]].credits * local.billing_cycles[pair[1]].credit_multiplier
    })
  }

  # Fixed prices per currency. A plan in this map gets pricing_mode = "by_currency".
  localized = {
    pro_monthly = { EUR = 4500, INR = 299900 }
    pro_annual  = { EUR = 45000, INR = 2999000 }
  }

  localized_prices = merge([
    for plan, amounts in local.localized : {
      for currency, amount in amounts : "${plan}_${currency}" => {
        plan     = plan
        currency = currency
        amount   = amount
      }
    }
  ]...)

  # One-time top-ups that add credits to the shared balance.
  credit_packs = {
    small  = { credits = 5000, price = 900 }
    medium = { credits = 25000, price = 3900 }
    large  = { credits = 100000, price = 12900 }
  }

  billing_events = [
    "credit.balance_low",
    "credit.overage_charged",
    "payment.failed",
    "payment.succeeded",
    "subscription.active",
    "subscription.cancelled",
    "subscription.on_hold",
    "subscription.plan_changed",
    "subscription.renewed",
  ]
}
