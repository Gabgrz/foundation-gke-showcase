# Foundation GKE Showcase

This repository sets up the foundation infrastructure for a GKE (Google Kubernetes Engine) showcase on Google Cloud Platform (GCP) using Terraform. It includes:

- Workload Identity Federation for GitHub Actions
- A deployer service account
- Enabling required APIs (STS, Cloud Resource Manager, IAM Credentials)
- A GCS bucket for Terraform remote state storage

The setup allows secure deployments from GitHub Actions without long-lived credentials.

## Prerequisites

- A GCP project (e.g., `gke-showroom`) already created.
- Google Cloud SDK (`gcloud`) installed.
- Terraform installed (version ~>1.5).
- A service account with Owner role (or sufficient permissions) and its JSON key file downloaded.
- GitHub repository access for configuring Actions.

## Setup Instructions

### 1. Configure Variables

Create a `terraform.tfvars` file in the root directory with the following content (replace with your values):

```
credentials_file = "/path/to/your/service-account-key.json"
project_id       = "gke-showroom"
github_owner     = "your-github-username"
```

- `credentials_file`: Path to your GCP service account key JSON (used for local runs; optional in CI).
- `project_id`: Your GCP project ID.
- `github_owner`: Your GitHub username or organization.

### 2. Bootstrap the Terraform State Bucket

Since the GCS bucket for state is managed by Terraform, we need to bootstrap it:

1. **Comment out the backend block** in `main.tf` (lines around the `backend "gcs"` section).

2. Initialize and apply Terraform locally:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

   This creates the bucket and other resources using local state.

3. **Uncomment the backend block** in `main.tf`.

4. Re-initialize Terraform and migrate state to GCS:

   ```
   terraform init -migrate-state
   ```

   Confirm the migration when prompted.

Now your state is stored remotely in `tfstate-gke-showroom` with versioning and lifecycle rules.

### 3. Verify and Use

- Run `terraform plan` to see changes.
- The configuration enables necessary APIs automatically.

## Resources Created

- **GCS Bucket**: `tfstate-gke-showroom` in `US-EAST1` for state storage, with versioning, lifecycle rules, and security settings.
- **Workload Identity Pool and Provider**: For GitHub OIDC integration.
- **Service Account**: `deployer` for deployments.
- **IAM Binding**: Allows GitHub repos under the specified owner to impersonate the SA.
- **APIs Enabled**: `sts.googleapis.com`, `cloudresourcemanager.googleapis.com`, `iamcredentials.googleapis.com`.

## Variables

| Variable          | Description                          | Type   | Required |
|-------------------|--------------------------------------|--------|----------|
| credentials_file | Path to GCP SA key JSON (local only) | string | No       |
| project_id       | GCP Project ID                       | string | Yes      |
| github_owner     | GitHub username/organization         | string | Yes      |

## CI/CD with GitHub Actions

This repo includes a workflow (`.github/workflows/terraform-plan.yml`) for running Terraform plan on pull requests.

- The workflow uses Workload Identity Federation to authenticate to GCP without secrets.
- Ensure your GitHub repo settings allow Actions to access the Workload Identity Provider.
- Grant the deployer SA necessary roles (e.g., for GKE creation in future modules).

To set up:

1. In GCP IAM, ensure the binding is applied.
2. In GitHub repo settings > Actions > General, allow workflows to run.

## Best Practices

- **Security**: Use Workload Identity for CI; avoid committing keys.
- **State Management**: Remote state prevents conflicts in teams.
- **Destroy Resources**: Run `terraform destroy` for cleanup (note: bucket has `prevent_destroy` lifecycle).
- **Extensions**: Add modules for GKE cluster, networking, etc.

For issues, check Terraform logs or GCP console.