resource "dodopayments_product" "credit_pack" {
  for_each = local.credit_packs

  name         = "${local.name_prefix}${each.value.credits} AI credits"
  description  = "A one-time top-up of ${each.value.credits} AI credits. Credits expire after 90 days."
  tax_category = "saas"

  price = {
    type          = "one_time_price"
    currency      = "USD"
    price         = each.value.price
    tax_inclusive = false
  }

  credit_entitlements = [{
    credit_entitlement_id = dodopayments_credit_entitlement.ai_credits.id
    credits_amount        = tostring(each.value.credits)
  }]

  metadata = {
    pack       = each.key
    managed_by = "terraform"
  }
}

# Pay what you want, with a minimum of $5 and a suggested $20.
resource "dodopayments_product" "sponsor" {
  name         = "${local.name_prefix}Sponsor the open-source SDKs"
  description  = "Pay what you want. All of it goes to the open-source SDK maintainers."
  tax_category = "saas"

  price = {
    type              = "one_time_price"
    currency          = "USD"
    price             = 500
    pay_what_you_want = true
    suggested_price   = 2000
    tax_inclusive     = false
  }
}
