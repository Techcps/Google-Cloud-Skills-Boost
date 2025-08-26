
gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/zone "$ZONE"

gcloud config set compute/region "$REGION"

gsutil -m cp -r gs://spls/gsp233/* .

cd tf-gke-k8s-service-lb

cat main.tf

cat k8s.tf

terraform init

terraform apply -var="region=$REGION" -var="location=$ZONE" --auto-approve
