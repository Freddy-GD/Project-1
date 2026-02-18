#!/usr/bin/env bash
#set -euo pipefail

Project_Tag="Project1"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=Project1-VPC" --query "Vpcs[0].VpcId" --output text)
PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Project1-Public-Subnet" --query "Subnets[0].SubnetId" --output text)
SEC_PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Project1-Public-Subnet-2" --query "Subnets[0].SubnetId" --output text)
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

echo "inbound created"
# Create Inbound Rule to allow SSH traffic
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --output text

echo "Created Inbound Rules to allow HTTP and SSH traffic on Security Group $SG_ID"

# Get the Instance ID of the EC2 instance
AMI_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" --query "Images[0].ImageId" --output text)

echo "Using AMI ID: $AMI_ID for EC2 instance creation"

# Create Key Pair
aws ec2 create-key-pair --key-name "Project1-Key" --query "KeyMaterial" --output text > Project1-Key.pem
chmod 400 Project1-Key.pem
echo "Created Key Pair and saved to Project1-Key.pem"

# Create EC2 Instance
INSTANCE1_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --key-name "Project1-Key" \
    --security-group-ids $SG_ID \
    --subnet-id $PUBLIC_SUBNET_ID \
    --associate-public-ip-address \
    --user-data "$(cat <<'EOF'
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd 
echo "Hello from Project1 Web Server!" > /var/www/html/index.html
EOF
    )" \
    --query 'Instances[0].InstanceId' --output text)


echo "Created an EC2 Instance in the first subnet with ID: $INSTANCE1_ID"

export INSTANCE1_ID

INSTANCE2_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --key-name "Project1-Key" \
    --security-group-ids $SG_ID \
    --subnet-id $SEC_PUBLIC_SUBNET_ID \
    --associate-public-ip-address \
    --user-data "$(cat <<'EOF'
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd 
echo "Hello from Project1 Web Server!" > /var/www/html/index.html
EOF
    )" \
    --query 'Instances[0].InstanceId' --output text)


echo "Created a second EC2 Instance in the second subnet with ID: $INSTANCE2_ID"

export INSTANCE2_ID
