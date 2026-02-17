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

# Retrieve the VPC ID for the existing VPC in case the environment variables are not set
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=Project1-VPC" --query 'Vpcs[0].VpcId' --output text)

# Getting the Public Route Table ID
PUBLIC_RT_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=Project1-Public-RT" --query RouteTables[0].RouteTableId --output text)


# Associate the new subnet with the public route table
aws ec2 associate-route-table --route-table-id $PUBLIC_RT_ID --subnet-id $SEC_PUBLIC_SUBNET_ID


