
gcloud auth list

gcloud services enable appengine.googleapis.com

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config get-value project)
gcloud config set project $DEVSHELL_PROJECT_ID

gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git


cd python-docs-samples/appengine/standard_python3/hello_world

cd python-docs-samples/appengine/standard_python3/hello_world


sed -i 's/Hello World!/Hello, Cruel World!/g' main.py

gcloud app create --region=$REGION

gcloud app deploy --quiet 
