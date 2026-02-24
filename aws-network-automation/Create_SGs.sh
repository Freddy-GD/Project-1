#!/usr/bin/env bash
#set -euo pipefail

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=Project1-VPC" --query "Vpcs[0].VpcId" --output text)


# Create Security Group
SG_ID=$(aws ec2 create-security-group --description "Web Access SG" \
    --group-name "Project1-Web-SG" \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value="Project1-Web-SG"},{Key=Project,Value=$Project_Tag}]" \
    --query GroupId --output text)

echo "Created Security Group with ID: $SG_ID"
export SG_ID

# Create Inbound Rule to allow HTTP traffic
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --output text

# Create Inbound Rule to allow SSH traffic
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --output text

echo "Created Inbound Rules to allow HTTP and SSH traffic on Security Group $SG_ID"
