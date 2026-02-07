#!usr/bin/env bash

REGION="us-east-2"
Project_Tag="Project1"

# Create VPC
VPC_ID=$(aws ec2 create-vpc \
     --cidr-block 172.1.0.0/16 \
     --region "$REGION" \
     --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value="Project1-VPC"},{Key=Project,Value=$Project_Tag}]" \
     --query 'Vpc.VpcId' --output text)

echo "Created VPC with ID: $VPC_ID"
export VPC_ID

#Allow DNS hostnames in the VPC, so any EC2 instance launched will have a human readable name instead of an IP.
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames

# Creare IGW

IGW_ID=$(aws ec2 create-internet-gateway \
     --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value="Project1-IGW"},{Key=Project,Value=$Project_Tag}]" \
     --query 'InternetGateway.InternetGatewayId' --output text)

echo "Created Internet Gateway with ID: $IGW_ID"
export IGW_ID

# Attach IGW to VPC
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "Attached Internet Gateway $IGW_ID to VPC $VPC_ID"

# Create Public Subnet
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 172.1.0.0/20 \
     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value="Project1-Public-Subnet"},{Key=Project,Value=$Project_Tag}]" \
     --query 'Subnet.SubnetId' --output text)

echo "Created Public Subnet with ID: $PUBLIC_SUBNET_ID"
export PUBLIC_SUBNET_ID

aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_ID --map-public-ip-on-launch
echo "Enabled auto-assign public IP for subnet $PUBLIC_SUBNET_ID"

# Create Private Subnet
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 172.1.16.0/20 \
     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value="Project1-Private-Subnet"},{Key=Project,Value=$Project_Tag}]" \
     --query 'Subnet.SubnetId' --output text)

echo "Created Private Subnet with ID: $PRIVATE_SUBNET_ID"
export PRIVATE_SUBNET_ID

# Create Public Route Table
PUBLIC_RT_ID=$(aws ec2 create-route-table \
     --vpc-id $VPC_ID \
     --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value="Project1-Public-RT"},{Key=Project,Value=$Project_Tag}]" \
     --query 'RouteTable.RouteTableId' --output text)

echo "Created Public Route Table with ID: $PUBLIC_RT_ID"
export PUBLIC_RT_ID

# Associate Public Route Table with Public Subnet
aws ec2 associate-route-table --route-table-id $PUBLIC_RT_ID --subnet-id $PUBLIC_SUBNET_ID
echo "Associated Public Route Table $PUBLIC_RT_ID with Subnet $PUBLIC_SUBNET_ID"

# Create Route to IGW in Public Route Table
aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

echo "Created route to Internet Gateway $IGW_ID in Public Route Table $PUBLIC_RT_ID"


    
PRIVATE_RT_ID=$(aws ec2 create-route-table \
     --vpc-id $VPC_ID \
     --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value="Project1-Private-RT"},{Key=Project,Value=$Project_Tag}]" \
     --query 'RouteTable.RouteTableId' --output text)   

echo "Created Private Route Table with ID: $PRIVATE_RT_ID"
    