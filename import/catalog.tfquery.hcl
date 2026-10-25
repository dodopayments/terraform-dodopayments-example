list "dodopayments_product" "subscriptions" {
  provider         = dodopayments
  include_resource = true
  limit            = 50

  config {
    recurring = true
  }
}

list "dodopayments_discount" "active" {
  provider         = dodopayments
  include_resource = true
  limit            = 50

  config {
    active = true
  }
}

list "dodopayments_meter" "all" {
  provider         = dodopayments
  include_resource = true
  limit            = 50
}
