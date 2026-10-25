# The plan picker. A customer changes plans inside this collection: an upgrade is billed now,
# a downgrade starts at the next renewal.
resource "dodopayments_product_collection" "plans" {
  name        = "${local.name_prefix}AI platform plans"
  description = "Starter, Pro and Scale, billed monthly or annually."

  groups = [
    for cycle in ["monthly", "annual"] : {
      group_name = local.billing_cycles[cycle].label
      products = [
        for tier in local.tier_order : { product_id = dodopayments_product.plan["${tier}_${cycle}"].id }
      ]
    }
  ]

  effective_at_on_upgrade             = "immediately"
  proration_billing_mode_on_upgrade   = "prorated_immediately"
  effective_at_on_downgrade           = "next_billing_date"
  proration_billing_mode_on_downgrade = "do_not_bill"
  on_payment_failure                  = "prevent_change"
}
