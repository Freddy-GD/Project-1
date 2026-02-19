#!/usr/bin/env bash
#set -euo pipefail

# Retrieve the VPC ID for the existing VPC in case the environment variables are not set
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=Project1-VPC" --query 'Vpcs[0].VpcId' --output text)

TG_ARN=$(aws elbv2 create-target-group \
    --name "Project1-TG" \
    --protocol HTTP \
    --port 80 \
    --vpc-id $VPC_ID \
    --target-type instance \
    --health-check-path "/" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

echo "Created Target Group with ARN: $TG_ARN"   
export TG_ARN