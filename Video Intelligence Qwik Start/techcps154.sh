

gcloud auth list

export PROJECT_ID=$(gcloud config get-value project)

gcloud services enable videointelligence.googleapis.com

gcloud iam service-accounts create quickstart

gcloud iam service-accounts keys create key.json --iam-account quickstart@$PROJECT_ID.iam.gserviceaccount.com

gcloud auth activate-service-account --key-file key.json

gcloud auth print-access-token

cat > request.json <<EOF
{
   "inputUri":"gs://spls/gsp154/video/train.mp4",
   "features": [
       "LABEL_DETECTION"
   ]
}
EOF

# Make annotate request
RESPONSE=$(curl -s -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://videointelligence.googleapis.com/v1/videos:annotate" \
  -d @request.json)

sleep 10

# Print the full operation name
OPERATION_NAME=$(echo "$RESPONSE" | grep -oP '"name":\s*"\K[^"]+')

export OPERATION_NAME

curl -s -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://videointelligence.googleapis.com/v1/$OPERATION_NAME"

