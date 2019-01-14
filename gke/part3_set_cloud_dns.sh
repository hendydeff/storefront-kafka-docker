#!/bin/bash
#
# Part 3: Update Cloud DNS A Records for new GKE cluster

# Constants - CHANGE ME!
readonly PROJECT='gke-confluent-atlas'
readonly DOMAIN='storefront-demo.com'
readonly ZONE='storefront-demo-com-zone'
readonly REGION='us-central1'
readonly TTL=300
readonly RECORDS=('dev.api' 'test.api' 'uat.api')

# Get load balancer IP address
readonly OLD_IP=$(gcloud dns record-sets list \
  --filter "name=${RECORDS[0]}.${DOMAIN}." --zone $ZONE \
  | awk 'NR==2 {print $4}')

readonly NEW_IP=$(gcloud compute forwarding-rules list \
  --filter "region:($REGION)" \
  | awk 'NR==2 {print $3}')

echo "Old LB IP Address: ${OLD_IP}"
echo "New LB IP Address: ${NEW_IP}"

# Update DNS records
gcloud dns record-sets transaction start --zone $ZONE

for record in ${RECORDS[@]}; do
  echo "${record}.${DOMAIN}."

  gcloud dns record-sets transaction remove \
    --name "${record}.${DOMAIN}." --ttl $TTL \
    --type A --zone $ZONE "${OLD_IP}"

  gcloud dns record-sets transaction add \
    --name "${record}.${DOMAIN}." --ttl $TTL \
    --type A --zone $ZONE "${NEW_IP}"
done

gcloud dns record-sets transaction execute --zone $ZONE