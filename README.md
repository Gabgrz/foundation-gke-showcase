# GCP Workload Identity Federation Bootstrap for Terraform CI/CD with GitHub Actions

This repository provides a foundational setup for integrating Google Cloud Platform (GCP) with Terraform and GitHub Actions using Workload Identity Federation. It enables secure, credential-free deployments from CI/CD pipelines to GCP.

Key components include:

- Workload Identity Federation for GitHub Actions authentication
- A deployer service account for resource management
- Enabling essential APIs (STS, Cloud Resource Manager, IAM Credentials)
- Owner service account and configuration for remote Terraform state in a GCS bucket (created via bootstrap script)

This bootstrap serves as a secure starting point for any GCP project using Terraform and GitHub Actions.

## Prerequisites

- A GCP project (e.g., `your-project-id`) already created.
- Google Cloud SDK (`gcloud`) installed.
- Terraform installed (version ~>1.5).
- GitHub repository access for configuring Actions.

## Setup Instructions

### 1. Authenticate with Google Cloud

Log in to your Google account via the CLI:

```
gcloud auth login
```

Set your project ID (replace `your-project-id` with your actual project ID):

```
gcloud config set project your-project-id
```

Obtain application default credentials:

```
gcloud auth application-default login
```

### 2. Bootstrap Service Account and GCS Bucket

Run the provided script to create the owner service account and the GCS bucket for Terraform state.

1. Make the script executable:

   ```

   chmod +x bootstrap/bootstrap.sh

   ```

2. Update the `PROJECT_ID` in the script to your project ID.

3. Run the script:

   ```

   ./bootstrap/bootstrap.sh

   ```

This creates:

- The `owner-sa` service account with Owner role.
- The `tfstate-gke-showroom` GCS bucket with versioning and lifecycle rules (customize the script if needed).

4. Download the JSON key for the service account:

   ```

   gcloud iam service-accounts keys create key.json \
     --iam-account=owner-sa@your-project-id.iam.gserviceaccount.com

   ```

   Store it securely outside the repo.

### 3. Configure Variables

Create a `terraform.tfvars` file in the root directory with:

```
credentials_file = "/path/to/your/service-account-key.json"
project_id       = "your-project-id"
github_owner     = "your-github-username"
```

- `credentials_file`: Path to your GCP SA key JSON (used for local runs; optional in CI).
- `project_id`: Your GCP project ID.
- `github_owner`: Your GitHub username or organization.

### 4. Apply Terraform

With the bootstrap complete, initialize and apply:

```
terraform init
terraform plan
terraform apply
```

The backend is configured to use the bucket, so state will be stored remotely from the first apply.

If you have existing local state, migrate it:

```
terraform init -migrate-state
```

## Resources Created

- **Workload Identity Pool and Provider**: For secure GitHub OIDC integration with GCP.
- **Service Account**: `deployer` for managing deployments and resources.
- **IAM Binding**: Allows GitHub repositories under the specified owner to impersonate the service account.
- **APIs Enabled**: `sts.googleapis.com`, `cloudresourcemanager.googleapis.com`, `iamcredentials.googleapis.com`.

(Note: The owner service account and GCS bucket are created via the bootstrap script, not Terraform.)

## Variables

| Variable          | Description                          | Type   | Required |
|-------------------|--------------------------------------|--------|----------|
| credentials_file | Path to GCP SA key JSON (local only) | string | No       |
| project_id       | GCP Project ID                       | string | Yes      |
| github_owner     | GitHub username/organization         | string | Yes      |

## CI/CD with GitHub Actions

This repo includes an example workflow (`.github/workflows/terraform-plan.yml`) for running Terraform plan on pull requests.

- The workflow leverages Workload Identity Federation to authenticate to GCP without storing secrets.
- Ensure your GitHub repo settings permit Actions to access the Workload Identity Provider.
- Grant the deployer SA appropriate roles based on your project's requirements.

To set up:

1. In GCP IAM, verify the binding is applied.
2. In GitHub repo settings > Actions > General, enable workflows to run.

## Best Practices

- **Security**: Rely on Workload Identity for CI authentication; never commit static credentials.
- **State Management**: Use remote state to avoid conflicts in collaborative environments.
- **Destroy Resources**: Execute `terraform destroy` for cleanup.
- **Extensions**: Expand with Terraform modules for your specific infrastructure needs (e.g., compute, storage, networking).

Have fun!