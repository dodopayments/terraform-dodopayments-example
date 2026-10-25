# Adopt objects that you made in the dashboard. Needs Terraform 1.14 or later.
#
#   terraform init
#   terraform query                                   # list the objects
#   terraform query -generate-config-out=generated.tf # write a resource and an import block for each
#
# Then move the blocks that you want into ../catalog and open a pull request.
terraform {
  required_version = ">= 1.14"

  required_providers {
    dodopayments = {
      source  = "dodopayments/dodopayments"
      version = "~> 0.2.1"
    }
  }
}

provider "dodopayments" {
  environment = "test_mode"
}
