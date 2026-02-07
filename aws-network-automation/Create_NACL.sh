#!/usr/bin/env bash

#set -euo pipefail

Project_Tag="Project1"
# Create NACL
NACL_ID=$(aws ec2 create-network-acl \
     --vpc-id $VPC_ID \
     --tag-specifications "ResourceType=network-acl,Tags=[{Key=Name,Value="Project1-NACL"},{Key=Project,Value=$Project_Tag}]" \
     --query 'NetworkAcl.NetworkAclId' --output text)   
echo "Created Network ACL with ID: $NACL_ID"
export NACL_ID

# Create Inbound Rule to allow HTTPs traffic
aws ec2 create-network-acl-entry \
     --network-acl-id $NACL_ID \
     --rule-number 100 \
     --protocol tcp \
     --port-range From=443,To=443 \
     --cidr-block 0.0.0.0/0 \
     --rule-action allow \
     --ingress
echo "Created Inbound Rule to allow HTTPS traffic on NACL $NACL_ID"

# Create Inbound Rule to allow HTTP traffic
aws ec2 create-network-acl-entry \
     --network-acl-id $NACL_ID \
     --rule-number 110 \
     --protocol tcp \
     --port-range From=80,To=80 \
     --cidr-block 0.0.0.0/0 \
     --rule-action allow \
     --ingress
echo "Created Inbound Rule to allow HTTP traffic on NACL $NACL_ID"

# Create Inbound Rule to allow SSH traffic
aws ec2 create-network-acl-entry \
     --network-acl-id $NACL_ID \
     --rule-number 120 \
     --protocol tcp \
     --port-range From=22,To=22 \
     --cidr-block 0.0.0.0/0 \
     --rule-action allow \
     --ingress
echo "Created Inbound Rule to allow SSH traffic on NACL $NACL_ID"

# Create Outbound Rule to allow all traffic
aws ec2 create-network-acl-entry \
     --network-acl-id $NACL_ID \
     --rule-number 100 \
     --protocol -1 \
     --cidr-block 0.0.0.0/0 \
     --rule-action allow \
     --egress
echo "Created Outbound Rule to allow all traffic on NACL $NACL_ID"

# Get the Default NACL ID and Association ID for the replacement of our custom NACL
ASSOCIATION_NACL_ID=$(aws ec2 describe-network-acls \
     --filters "Name=vpc-id,Values=$VPC_ID" "Name=default,Values=true" \
     --query 'NetworkAcls[0].Associations[0].NetworkAclAssociationId' --output text)

echo "Found Default Network ACL Association with ID: $ASSOCIATION_NACL_ID"

# Replace the Default NACL Association with our Custom NACL
aws ec2 replace-network-acl-association \
     --association-id $ASSOCIATION_NACL_ID \
     --network-acl-id $NACL_ID
echo "Replaced Default NACL Association with Custom NACL $NACL_ID"