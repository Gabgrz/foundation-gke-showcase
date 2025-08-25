#!/bin/bash

PROJECT_ID="gke-showroom"

# Get the directory of the script (handles runs from other dirs)
SCRIPT_DIR=$(dirname "$0")

# Set the project
gcloud config set project $PROJECT_ID

# Create Owner service account
gcloud iam service-accounts create owner-sa \
  --display-name="Owner Service Account" \
  --project=gke-showroom

# Assign the Owner role to the service account at the project level
gcloud projects add-iam-policy-binding gke-showroom \
  --member="serviceAccount:owner-sa@gke-showroom.iam.gserviceaccount.com" \
  --role="roles/owner"

# Create the bucket
gcloud storage buckets create gs://tfstate-gke-showroom \
  --location=US-EAST1 \
  --default-storage-class=STANDARD \
  --uniform-bucket-level-access \
  --public-access-prevention \
  --lifecycle-file="$SCRIPT_DIR/lifecycle.json"