

gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
 
PROJECT_ID=$(gcloud config get-value project)


gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com \
  redis.googleapis.com \
  vpcaccess.googleapis.com


sleep 30

REDIS_INSTANCE=customerdb

gcloud redis instances create $REDIS_INSTANCE \
 --size=2 --region=$REGION \
 --redis-version=redis_6_x

gcloud redis instances describe $REDIS_INSTANCE --region=$REGION

REDIS_IP=$(gcloud redis instances describe $REDIS_INSTANCE --region=$REGION --format="value(host)"); echo $REDIS_IP

REDIS_PORT=$(gcloud redis instances describe $REDIS_INSTANCE --region=$REGION --format="value(port)"); echo $REDIS_PORT

gcloud compute networks vpc-access connectors create test-connector \
    --region $REGION \
    --range 10.8.0.0/28

# gcloud compute networks vpc-access connectors describe test-connector --region $REGION


TOPIC=add_redis

gcloud pubsub topics create $TOPIC

mkdir ~/redis-pubsub && cd $_
touch main.py && touch requirements.txt


cat > main.py <<EOF_CP
import os
import base64
import json
import redis
import functions_framework

redis_host = os.environ.get('REDISHOST', 'localhost')
redis_port = int(os.environ.get('REDISPORT', 6379))
redis_client = redis.StrictRedis(host=redis_host, port=redis_port)

# Triggered from a message on a Pub/Sub topic.
@functions_framework.cloud_event
def addToRedis(cloud_event):
    # The Pub/Sub message data is stored as a base64-encoded string in the cloud_event.data property
    # The expected value should be a JSON string.
    json_data_str = base64.b64decode(cloud_event.data["message"]["data"]).decode()
    json_payload = json.loads(json_data_str)
    response_data = ""
    if json_payload and 'id' in json_payload:
        id = json_payload['id']
        data = redis_client.set(id, json_data_str)
        response_data = redis_client.get(id)
        print(f"Added data to Redis: {response_data}")
    else:
        print("Message is invalid, or missing an 'id' attribute")
EOF_CP


cat > requirements.txt <<EOF_CP
functions-framework==3.2.0
redis==4.3.4
EOF_CP

export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"


#!/bin/bash
SERVICE_NAME="python-pubsub-function"

deploy_function() {
  gcloud functions deploy python-pubsub-function \
    --runtime=python310 \
    --region=$REGION \
    --source=. \
    --entry-point=addToRedis \
    --trigger-topic=$TOPIC \
    --vpc-connector projects/$PROJECT_ID/locations/$REGION/connectors/test-connector \
    --set-env-vars REDISHOST=$REDIS_IP,REDISPORT=$REDIS_PORT
}

while true; do
  deploy_function
  if gcloud functions describe $SERVICE_NAME --region $REGION &> /dev/null; then
    echo "Function deployed successfully! Check it out: https://www.youtube.com/@techcps"
    break
  else
    echo "Deployment failed. Please subscribe to techcps: https://www.youtube.com/@techcps"
    sleep 10
  fi
done

sleep 15

gcloud pubsub topics publish $TOPIC --message='{"id": 1234, "firstName": "Lucas" ,"lastName": "Sherman", "Phone": "555-555-5555"}'


mkdir ~/redis-http && cd $_
touch main.py && touch requirements.txt



cat > main.py <<EOF_CP
import os
import redis
from flask import request
import functions_framework

redis_host = os.environ.get('REDISHOST', 'localhost')
redis_port = int(os.environ.get('REDISPORT', 6379))
redis_client = redis.StrictRedis(host=redis_host, port=redis_port)

@functions_framework.http
def getFromRedis(request):
    response_data = ""
    if request.method == 'GET':
        id = request.args.get('id')
        try:
            response_data = redis_client.get(id)
        except RuntimeError:
            response_data = ""
        if response_data is None:
            response_data = ""
    return response_data
EOF_CP


cat > requirements.txt <<EOF_CP
functions-framework==3.2.0
redis==4.3.4
EOF_CP




#!/bin/bash
SERVICE_NAME="http-get-redis"

deploy_function() {
    gcloud functions deploy http-get-redis \
    --gen2 \
    --runtime python310 \
    --entry-point getFromRedis \
    --source . \
    --region $REGION \
    --trigger-http \
    --timeout 600s \
    --max-instances 1 \
    --vpc-connector projects/$PROJECT_ID/locations/$REGION/connectors/test-connector \
    --set-env-vars REDISHOST=$REDIS_IP,REDISPORT=$REDIS_PORT \
    --no-allow-unauthenticated
}

while true; do
  deploy_function
  if gcloud functions describe $SERVICE_NAME --region $REGION &> /dev/null; then
    echo "Function deployed successfully! Check it out: https://www.youtube.com/@techcps"
    break
  else
    echo "Deployment failed. Please subscribe to techcps: https://www.youtube.com/@techcps"
    sleep 10
  fi
done

sleep 15

FUNCTION_URI=$(gcloud functions describe http-get-redis --gen2 --region $REGION --format "value(serviceConfig.uri)"); echo $FUNCTION_URI

curl -H "Authorization: bearer $(gcloud auth print-identity-token)" "${FUNCTION_URI}?id=1234"
 

gcloud storage cp gs://cloud-training/CBL492/startup.sh .


gcloud compute instances create webserver-vm \
--image-project=debian-cloud \
--image-family=debian-11 \
--metadata-from-file=startup-script=./startup.sh \
--machine-type e2-standard-2 \
--tags=http-server \
--scopes=https://www.googleapis.com/auth/cloud-platform \
--zone $ZONE

gcloud compute --project=$PROJECT_ID \
 firewall-rules create default-allow-http \
 --direction=INGRESS \
 --priority=1000 \
 --network=default \
 --action=ALLOW \
 --rules=tcp:80 \
 --source-ranges=0.0.0.0/0 \
 --target-tags=http-server


sleep 15


VM_INT_IP=$(gcloud compute instances describe webserver-vm --format='get(networkInterfaces[0].networkIP)' --zone $ZONE); echo $VM_INT_IP

VM_EXT_IP=$(gcloud compute instances describe webserver-vm --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone $ZONE); echo $VM_EXT_IP


mkdir ~/vm-http && cd $_
touch main.py && touch requirements.txt


cat > main.py <<EOF_CP
import functions_framework
import requests

@functions_framework.http
def connectVM(request):
    resp_text = ""
    if request.method == 'GET':
        ip = request.args.get('ip')
        try:
            response_data = requests.get(f"http://{ip}")
            resp_text = response_data.text
        except RuntimeError:
            print ("Error while connecting to VM")
    return resp_text
EOF_CP

cat > requirements.txt <<EOF_CP
functions-framework==3.2.0
Werkzeug==2.3.7
flask==2.1.3
requests==2.28.1
EOF_CP



#!/bin/bash
SERVICE_NAME="vm-connector"

deploy_function() {
gcloud functions deploy vm-connector \
 --runtime python310 \
 --entry-point connectVM \
 --source . \
 --region $REGION \
 --trigger-http \
 --timeout 10s \
 --max-instances 1 \
 --no-allow-unauthenticated
}

while true; do
  deploy_function
  if gcloud functions describe $SERVICE_NAME --region $REGION &> /dev/null; then
    echo "Function deployed successfully! Check it out: https://www.youtube.com/@techcps"
    break
  else
    echo "Deployment failed. Please subscribe to techcps: https://www.youtube.com/@techcps"
    sleep 10
  fi
done

sleep 15


FUNCTION_URI=$(gcloud functions describe vm-connector --region $REGION --format='value(httpsTrigger.url)'); echo $FUNCTION_URI

curl -H "Authorization: bearer $(gcloud auth print-identity-token)" "${FUNCTION_URI}?ip=$VM_EXT_IP"

curl -H "Authorization: bearer $(gcloud auth print-identity-token)" "${FUNCTION_URI}?ip=$VM_INT_IP"

gcloud services disable cloudfunctions.googleapis.com

gcloud services enable cloudfunctions.googleapis.com


#!/bin/bash
SERVICE_NAME="vm-connector"

deploy_function() {
gcloud functions deploy vm-connector \
 --runtime python310 \
 --entry-point connectVM \
 --source . \
 --region $REGION \
 --trigger-http \
 --timeout 10s \
 --max-instances 1 \
 --no-allow-unauthenticated \
 --vpc-connector projects/$PROJECT_ID/locations/$REGION/connectors/test-connector
}

while true; do
  deploy_function
  if gcloud functions describe $SERVICE_NAME --region $REGION &> /dev/null; then
    echo "Function deployed successfully! Check it out: https://www.youtube.com/@techcps"
    break
  else
    echo "Deployment failed. Please subscribe to techcps: https://www.youtube.com/@techcps"
    sleep 10
  fi
done



