terraform {
  required_version = ">= 1.12"

  required_providers {
    dodopayments = {
      source  = "dodopayments/dodopayments"
      version = "~> 0.2.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 8.8"
    }
  }

  # CI gives the prefix: `catalog/main` for the live catalog, `e2e/<run id>` for a nightly run.
  # To try the catalog on your machine, copy backend_override.tf.example to backend_override.tf.
  backend "gcs" {
    bucket = "dodopayments-tf-example-tfstate"
    prefix = "catalog/main"
  }
}

# The provider reads the API key from the DODO_PAYMENTS_API_KEY environment variable.
provider "dodopayments" {
  environment = var.dodo_environment
}

provider "google" {
  project = var.gcp_project_id
  region  = "asia-south1"
}
