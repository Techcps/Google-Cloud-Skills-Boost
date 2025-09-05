
gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone "$ZONE"

gcloud compute instances stop Instance_name --zone="$ZONE"

sleep 10

gcloud compute instances set-machine-type Instance_name --machine-type e2-medium --zone="$ZONE"

sleep 10

gcloud compute instances start lab-vm  --zone="$ZONE"


