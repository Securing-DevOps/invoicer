#!/usr/bin/env bash

# Create the Kubernetes cluster
gcloud container clusters create invoicer --scopes "cloud-platform" --num-nodes 2 --zone us-east1

# Create the database instance
gcloud sql instances create invoicerdb --tier db-f1-micro --region us-east1 --database-version=POSTGRES_9_6
gcloud sql databases create invoicer --instance=invoicerdb

# Create a database user on the instance
gcloud sql users create invoicerapp --instance=invoicerdb --password=cariboumaurice

# Upload database user to kubernetes secret
kubectl create secret generic cloudsql-db-credentials --from-literal=username=invoicerapp --from-literal=password=cariboumaurice

# Create a service account
gcloud iam service-accounts create invoicer

# Grant editor role to service account
gcloud projects add-iam-policy-binding ulfr-test20180906 --member serviceAccount:invoicer@ulfr-test20180906.iam.gserviceaccount.com --role roles/editor

# Download service account key
gcloud iam service-accounts keys create /tmp/invoicer-sa.json --iam-account invoicer@ulfr-test20180906.iam.gserviceaccount.com

# Upload service account key to kubernetes secret
kubectl create secret generic cloudsql-instance-credentials --from-file=credentials.json=/tmp/invoicer-sa.json

# Create the Kubernetes Workload
kubectl create -f invoicer-gcp-kube.yaml

# Expose the service
kubectl apply -f invoicer-https-service.yaml

# Get a cert from LE
GANDIV5_API_KEY=************* lego -a --email="julien@securing-devops.com" --domains="invoicer-gcp.securing-devops.com" --dns="gandiv5" --key-type ec256 run

# Upload letsencrypt certs to kubernetes secret
kubectl create secret tls invoicer-tls --key .lego/certificates/invoicer-gcp.securing-devops.com.key --cert invoicer-gcp.securing-devops.com.crt

# Create the HTTPS ingress
kubectl apply -f invoicer-https-ingress.yaml
