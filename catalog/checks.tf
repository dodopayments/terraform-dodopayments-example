# A check gives a warning and does not stop the run. The drift workflow reports each warning.
# Do not put a data source in a check block here: Terraform reads it again during apply,
# and `plan -detailed-exitcode` then always reports a change.

check "launch_promo_window" {
  assert {
    condition     = timecmp(timeadd(plantimestamp(), "720h"), var.launch_promo_ends_at) < 0
    error_message = "The launch promotion ends in less than 30 days (${var.launch_promo_ends_at}). Extend launch_promo_ends_at or remove the discount."
  }
}

check "credit_pack_volume_pricing" {
  assert {
    condition = alltrue([
      for pair in [["small", "medium"], ["medium", "large"]] :
      local.credit_packs[pair[1]].price / local.credit_packs[pair[1]].credits < local.credit_packs[pair[0]].price / local.credit_packs[pair[0]].credits
    ])
    error_message = "A larger credit pack must cost less for each credit than a smaller pack."
  }
}
