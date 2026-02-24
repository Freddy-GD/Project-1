#!/usr/bin/env bash
#set -euo pipefail

# Retrieve the VPC ID for the existing VPC in case the environment variables are not set
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=Project1-VPC" --query 'Vpcs[0].VpcId' --output text)

# Retrieve instances ids to register with the target group
Instance1_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=Project1-Public-Instance-1" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

Instance2_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=Project1-Public-Instance-2" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

# Retrieve the Public Subnets IDs for the ALB
PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=Project1-Public-Subnet" \
  --query 'Subnets[0].SubnetId' \
  --output text)

SEC_PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=Project1-Public-Subnet-2" \
  --query 'Subnets[0].SubnetId' \
  --output text)

# Create Inbound Rule to allow HTTP traffic to allow Http traffic only from the ALB SG
ec2_sg_id=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=Project1-Web-SG" --query 'SecurityGroups[0].GroupId' --output text)

# Create Target Group for the ALB
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

# Register the EC2 instances with the Target Group
aws elbv2 register-targets \
    --target-group-arn $TG_ARN \
    --targets Id=$Instance1_ID Id=$Instance2_ID 

echo "Registered instances $Instance1_ID and $Instance2_ID with Target Group $TG_ARN"

# Create a Security Group for the ALB
SG_ALB_ID=$(aws ec2 create-security-group --description "ALB SG" \
    --group-name "Project1-ALB-SG" \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value="Project1-ALB-SG"}]" \
    --query SecurityGroups[0].GroupId \
    --output text)
echo "Created Security Group for ALB with ID: $SG_ALB_ID"
export SG_ALB_ID


LB_ARN=$(aws elbv2 create-load-balancer \
    --name "Project1-ALB" \
    --subnets $PUBLIC_SUBNET_ID $SEC_PUBLIC_SUBNET_ID \
    --security-groups $SG_ALB_ID \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

echo "Created Application Load Balancer with ARN: $LB_ARN"
export LB_ARN

# Adding inbound rule to allow HTTP traffic to the ALB Security Group 
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ALB_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --output text   

echo "Created Inbound Rule to allow HTTP traffic on Security Group $SG_ALB_ID"

# Adding an inbound rule to the orignal SG that's holding the EC2 instances to allow HTTP traffic only from the ALB SG
aws ec2 authorize-security-group-ingress \
    --group-id $ec2_sg_id \
    --protocol tcp \
    --port 80 \
    --source-group $SG_ALB_ID \
    --output text

echo "Created Inbound Rule to allow HTTP traffic from ALB SG $SG_ALB_ID to EC2 SG $ec2_sg_id"

# Removing the original inbound rule that allowed HTTP traffic from anywhere to the ec2 SG
aws ec2 revoke-security-group-ingress \
    --group-id $ec2_sg_id \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --output text

echo "Revoked Inbound Rule to allow HTTP traffic from anywhere to EC2 SG $ec2_sg_id, now only allowing traffic from ALB SG $SG_ALB_ID"

# Create Listener for the ALB
LISTENER_ARN=$(aws elbv2 create-listener \
    --load-balancer-arn $LB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN \
    --query 'Listeners[0].ListenerArn' \
    --output text)

echo "Created Listener for ALB with ARN: $LISTENER_ARN"
export LISTENER_ARN

