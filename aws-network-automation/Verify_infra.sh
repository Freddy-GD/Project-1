#!/usr/bin/env bash
set -euo pipefail

# LOG_FILE="verify_infra_$(date +%Y%m%d_%H%M%S).log"
# exec > >(tee -a "$LOG_FILE") 2>&1
# set -x

echo "===== VERIFYING AWS INFRASTRUCTURE FOR PROJECT1 ====="

# -------------------------
# Project Variables
# -------------------------
VPC_NAME="Project1-VPC"
EC2_TAG="Project1-Private-Instance"
BASTION_TAG="Project1-Bashion-Instance"
ALB_NAME="Project1-ALB"
EC2_SG_NAME="Project1-Web-SG"
BASTION_SG_NAME="Project1-Bashion-SG"
ALB_SG_NAME="Project1-ALB-SG"

# -------------------------
# VPC and Subnets
# -------------------------
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query "Vpcs[0].VpcId" --output text)
echo "VPC ID: $VPC_ID"

echo "Public Subnets:"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=Project1-Public-Subnet" --query 'Subnets[].SubnetId' --output table

echo "Private Subnets:"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=Project1-Private-Subnet*" --query 'Subnets[].SubnetId' --output table

# -------------------------
# Security Groups
# -------------------------
echo "Security Groups:"
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[*].[GroupName,GroupId]' --output table

# -------------------------
# EC2 Instances
# -------------------------
echo "Private EC2 Instances:"
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$EC2_TAG*" \
    --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,State.Name,SubnetId]' \
    --output table

echo "Bastion Host:"
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$BASTION_TAG" \
    --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name]' \
    --output table

BASTION_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$BASTION_TAG" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "Bastion Public IP: $BASTION_IP"

# -------------------------
# ALB Verification
# -------------------------
ALB_DNS=$(aws elbv2 describe-load-balancers --names $ALB_NAME --query 'LoadBalancers[0].DNSName' --output text)
echo "ALB DNS: $ALB_DNS"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$ALB_DNS)
echo "HTTP status from ALB: $HTTP_STATUS"

if [ "$HTTP_STATUS" == "200" ]; then
    echo "✅ ALB is responding correctly"
else
    echo "⚠️ ALB response not OK. HTTP status: $HTTP_STATUS"
fi

# -------------------------
# Network ACLs
# -------------------------
echo "Network ACLs:"
aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkAcls[*].[NetworkAclId,IsDefault]' --output table

# -------------------------
# Route Tables
# -------------------------
echo "Route Tables:"
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[*].[RouteTableId,Routes]' --output table

# -------------------------
# Connectivity Tests (Optional)
# -------------------------
echo "Attempting ping from Bastion to Private EC2s (requires SSH into Bastion):"
PRIVATE_EC2_IPS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$EC2_TAG*" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
echo "Private EC2 IPs: $PRIVATE_EC2_IPS"

echo -e "\nTo test connectivity manually:"
echo "ssh -i Project1-Key.pem ec2-user@$BASTION_IP"
echo "Then from Bastion: ping -c 3 <Private_EC2_IP>"

# -------------------------
# Summary
# -------------------------
echo -e "\n✅ Verification Complete!"
echo "Check above outputs for any discrepancies."
echo "ALB should return HTTP 200, EC2 instances should be running in correct subnets, SGs and NACLs properly configured."