# Dodo Payments Terraform example: an AI SaaS catalog

This repository manages a complete pricing catalog in [Dodo Payments](https://dodopayments.com) with the
[Dodo Payments Terraform provider](https://registry.terraform.io/providers/dodopayments/dodopayments/latest).
A pull request shows the plan. A merge to `main` applies it. Each night, a workflow looks for changes made
in the dashboard, and a second workflow builds the full catalog from nothing, uses it, and destroys it.

The catalog runs in **test mode**. No real money moves.

## The pricing model

| Part | What it does | Terraform features |
|---|---|---|
| 3 meters | API requests (count, with a filter), LLM tokens (sum), vector storage (max) | `for_each`, `jsonencode()` for the filter |
| AI credits | One credit balance for all plans and packs. 50% rollover for 2 months, expiry after 90 days, overage on the invoice | `dodopayments_credit_entitlement` |
| 5 feature flags | API access, team workspaces, SSO, audit logs, dedicated capacity | `dodopayments_entitlement` |
| 6 subscription plans | Starter, Pro and Scale, monthly and annual. Trials with no card on Pro and Scale. PPP on Starter | `setproduct()` builds the 3 × 2 matrix from two maps |
| Localized prices | Pro in EUR and INR at fixed prices | `pricing_mode`, `dodopayments_product_localized_price` |
| Enterprise | $499 platform fee, metered requests and storage, LLM tokens paid from credits | `usage_based_price` with 3 meters |
| 2 add-ons | Extra seat, priority support | `dodopayments_addon` |
| 3 credit packs + 1 sponsor product | One-time top-ups, and a pay-what-you-want product | `one_time_price`, `pay_what_you_want` |
| Plan collection | The plan picker. An upgrade is billed now and prorated. A downgrade starts at renewal | `dodopayments_product_collection` |
| 3 discounts | `LAUNCH20` (annual plans, first year), `STUDENT50` (new customers, capped), `WELCOME10` (flat, a different amount in each currency) | `restricted_to`, `currency_options`, `subscription_cycles` |
| Billing webhook | 9 event types. The signing secret goes to GCP Secret Manager and never to the state | `ephemeral` resource + write-only argument |

All prices are data in [`catalog/locals.tf`](catalog/locals.tf). To change a price, change one number and open a pull request.

Terraform also checks the model:

- A precondition stops the plan if an annual price does not save at least 10%.
- A `check` warns 30 days before the launch promotion ends.
- A `check` warns if a larger credit pack does not cost less for each credit.
- Variable validation rejects a webhook URL without HTTPS and a discount code prefix that is too long.

## Layout

```
catalog/        the catalog (state: gs://dodopayments-tf-example-tfstate/catalog/main)
import/         adopt objects from the dashboard with `terraform query` (Terraform 1.14+)
scripts/        plan summary for pull requests
.github/        validate, plan, apply, drift and e2e workflows
```

## Workflows

| Workflow | When | What |
|---|---|---|
| `validate` | Each push and pull request | `fmt`, `validate` on Terraform 1.12 and 1.17, `tflint` |
| `plan` | Pull request | Plans against the live catalog and puts a summary table in a comment |
| `apply` | Merge to `main` | Plans again, applies that plan file, then confirms that a new plan is empty |
| `drift` | Each night, 02:30 UTC | Opens a `drift` issue if the dashboard differs from `main` or a check fails. Closes it when the catalog matches again |
| `e2e` | Each night, 03:30 UTC | Builds a separate copy of the catalog on Terraform 1.12 and 1.17, confirms an empty second plan, makes two checkouts, runs `terraform query`, and destroys the copy |

The workflows get GCP access through Workload Identity Federation. There is no service account key.
The Dodo Payments API key is the `DODO_PAYMENTS_API_KEY` repository secret.

## Try it

You need Terraform 1.12 or later and a Dodo Payments test-mode API key.

```bash
export DODO_PAYMENTS_API_KEY=...   # Dashboard → Developer → API keys, in test mode
cd catalog
cp backend_override.tf.example backend_override.tf   # keep the state on your machine
terraform init
terraform apply -var gcp_project_id=null -var resource_prefix=$USER
terraform destroy -var gcp_project_id=null -var resource_prefix=$USER
```

`resource_prefix` puts your name before each object name, so that your copy does not mix with other objects.
`gcp_project_id=null` skips Secret Manager.

When you delete a product, meter, add-on, credit entitlement or collection, Terraform archives it. The API cannot delete these objects.
When you delete a discount or webhook, Terraform deletes it.

## GCP setup

The state and the webhook secret are in the GCP project `dodopayments-tf-example`, which has nothing else in it. It was set up with these commands:

```bash
P=dodopayments-tf-example
gcloud projects create $P --organization=592487956937
gcloud billing projects link $P --billing-account=0153FC-C2F7C7-212A25
gcloud services enable storage.googleapis.com iam.googleapis.com iamcredentials.googleapis.com \
  sts.googleapis.com secretmanager.googleapis.com --project=$P

gcloud storage buckets create gs://$P-tfstate --project=$P --location=asia-south1 \
  --uniform-bucket-level-access --public-access-prevention
gcloud storage buckets update gs://$P-tfstate --versioning
# The lifecycle rules delete e2e states after 14 days, and old state versions after 30 days.

gcloud iam service-accounts create terraform-ci --project=$P
gcloud storage buckets add-iam-policy-binding gs://$P-tfstate \
  --member=serviceAccount:terraform-ci@$P.iam.gserviceaccount.com --role=roles/storage.objectAdmin
gcloud projects add-iam-policy-binding $P \
  --member=serviceAccount:terraform-ci@$P.iam.gserviceaccount.com --role=roles/secretmanager.admin

# Only this repository can get a token. The condition uses the numeric IDs, because a deleted name can be registered again.
gcloud iam workload-identity-pools create github --project=$P --location=global
gcloud iam workload-identity-pools providers create-oidc terraform-example --project=$P \
  --location=global --workload-identity-pool=github \
  --issuer-uri=https://token.actions.githubusercontent.com \
  --attribute-mapping=google.subject=assertion.sub,attribute.repository_id=assertion.repository_id,attribute.repository_owner_id=assertion.repository_owner_id \
  --attribute-condition="assertion.repository_owner_id == '168640166' && assertion.repository_id == '1433452721'"
gcloud iam service-accounts add-iam-policy-binding terraform-ci@$P.iam.gserviceaccount.com \
  --project=$P --role=roles/iam.workloadIdentityUser \
  --member=principalSet://iam.googleapis.com/projects/887237639149/locations/global/workloadIdentityPools/github/attribute.repository_id/1433452721
```

A pull request from a fork gets no secret and no token, so the `plan` and `e2e` jobs do not run for it.

## License

Apache 2.0
