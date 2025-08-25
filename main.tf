terraform {
  required_version = "~> 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.49.2"
    }
  }

  backend "gcs" {
    bucket = "tfstate-gke-showroom"
    prefix = "terraform/state"
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
}

resource "google_storage_bucket" "terraform_state" {
  name                        = "tfstate-gke-showroom" # must be globally unique
  location                    = "US-EAST1"             # or "US"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 30 # Deletes only noncurrent versions after 30 days
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    prevent_destroy = true # Prevents accidental TF destroy
  }

  labels = {
    purpose = "terraform-state"
  }
}


# Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "gh-pool"
  display_name              = "GitHub OIDC Pool"
  description               = "Workload identity pool for GitHub"
}

# Provider (GitHub)
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "gh-provider"
  display_name                       = "GitHub Provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # Map the GitHub claims we’ll use
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository_owner" = "assertion.repository_owner" # will be your username
    "attribute.repository"       = "assertion.repository"
    "attribute.ref"              = "assertion.ref"
    "attribute.workflow_ref"     = "assertion.workflow_ref"
  }

  # Minimal guardrail: only tokens where the owner == your username
  attribute_condition = "attribute.repository_owner == '${var.github_owner}'"
}

resource "google_service_account" "deployer" {
  account_id   = "deployer"
  display_name = "Deployer Service Account"
}

resource "google_service_account_iam_member" "github_any_repo_under_me" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository_owner/${var.github_owner}"
}