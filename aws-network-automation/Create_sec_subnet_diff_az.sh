#!/usr/bin/env bash

##set -euo pipefail

Project_Tag="Project1"

# Getting the vpc id 
VPC_ID=$(aws ec2 describe-vpcs \
     --filters "Name=tag:Name,Values=Project1-VPC" \
     --query 'Vpcs[0].VpcId' --output text)

# Create Secondary Subnet in a different AZ
SEC_PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 172.1.32.0/20 \
     --availability-zone "us-east-2a" \
     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value="Project1-Public-Subnet-2"},{Key=Project,Value=$Project_Tag}]" \
     --query 'Subnet.SubnetId' --output text)

echo "Created Secondary Public Subnet with ID: $SEC_PUBLIC_SUBNET_ID"
export SEC_PUBLIC_SUBNET_ID
