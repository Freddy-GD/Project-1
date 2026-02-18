#!/usr/bin/env bash
#set -euo pipefail

Project_Tag="Project1"

#Create an Elastic IP address for the NAT Gateway
EIP_ALLOC_ID=$(aws ec2 allocate-address --domain vpc \
  --query 'AllocationId' --output text)

echo "Allocated Elastic IP with Allocation ID: $EIP_ALLOC_ID"

export EIP_ALLOC_ID

# Retrieve Public Subnet ID (example using tag)
PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=Project1-Public-Subnet-2" \
  --query 'Subnets[0].SubnetId' \
  --output text)

NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_ID \
  --allocation-id $EIP_ALLOC_ID \
  --query 'NatGateway.NatGatewayId' \
  --output text)

echo "Created NAT Gateway with ID: $NAT_GW_ID"

export NAT_GW_ID

echo "Waiting for NAT Gateway to become available..."

aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

echo "NAT Gateway $NAT_GW_ID is now available"

PRIVATE_RT_ID=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=Project1-Private-RT" \
  --query 'RouteTables[0].RouteTableId' \
  --output text)

aws ec2 create-route \
    --route-table-id $PRIVATE_RT_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id $NAT_GW_ID 

echo "Added route to NAT Gateway $NAT_GW_ID in Private Route Table $PRIVATE_RT_ID"
