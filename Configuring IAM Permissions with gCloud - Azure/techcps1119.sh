

gcloud config configurations activate default

gcloud config configurations activate user2

echo "export PROJECTID2=$PROJECT_ID2" >> ~/.bashrc

. ~/.bashrc
gcloud config set project $PROJECT_ID2 --quiet

gcloud config configurations activate default

sudo yum -y install epel-release
sudo yum -y install jq

echo "export USERID2=$USER2" >> ~/.bashrc


. ~/.bashrc
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member user:$USER2 --role=roles/viewer


gcloud config configurations activate user2

gcloud config set project $PROJECT_ID2

gcloud compute instances list

# export ZONE=$ZONE
# gcloud compute instances create lab-2 --zone=$ZONE

gcloud config configurations activate default

gcloud iam roles create devops --project $PROJECT_ID2 --permissions "compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount"


gcloud projects add-iam-policy-binding $PROJECT_ID2 --member user:$USER2 --role=roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding $PROJECT_ID2 --member user:$USER2 --role=projects/$PROJECT_ID2/roles/devops


gcloud config configurations activate user2

gcloud compute instances create lab-2 --zone "$ZONE"


gcloud compute instances list

gcloud config configurations activate default

gcloud config set project $PROJECT_ID2

gcloud iam service-accounts create devops --display-name devops

gcloud iam service-accounts list  --filter "displayName=devops"

SA=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=devops")


gcloud projects add-iam-policy-binding $PROJECT_ID2 --member serviceAccount:$SA --role=roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding $PROJECT_ID2 --member serviceAccount:$SA --role=roles/compute.instanceAdmin

gcloud compute instances create lab-3 --zone "$ZONE" --service-account $SA --scopes "https://www.googleapis.com/auth/compute"


