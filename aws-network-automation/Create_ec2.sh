#!/usr/bin/env bash
#set -euo pipefail

Project_Tag="Project1"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=Project1-VPC" --query "Vpcs[0].VpcId" --output text)
# PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Project1-Public-Subnet" --query "Subnets[0].SubnetId" --output text)
# SEC_PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Project1-Public-Subnet-2" --query "Subnets[0].SubnetId" --output text)
First_Private_Subnet=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Project1-Private-Subnet" --query 'Subnets[0].SubnetId' --output text)
Second_Private_Subnet=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Project1-Private-Subnet-2" --query 'Subnets[0].SubnetId' --output text)
SG_ID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=Project1-Web-SG" --query 'SecurityGroups[0].GroupId' --output text)

# Get the Instance ID of the EC2 instance
AMI_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" --query "Images[0].ImageId" --output text)

echo "Using AMI ID: $AMI_ID for EC2 instance creation"

# Create Key Pair
aws ec2 create-key-pair --key-name "Project1-Key" --query "KeyMaterial" --output text > Project1-Key.pem
chmod 400 Project1-Key.pem
echo "Created Key Pair and saved to Project1-Key.pem"

# Create EC2 Instance
# INSTANCE1_ID=$(aws ec2 run-instances \
#     --image-id $AMI_ID \
#     --instance-type t3.micro \
#     --key-name "Project1-Key" \
#     --security-group-ids $SG_ID \
#     --subnet-id $PUBLIC_SUBNET_ID \
#     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Project1-Public-Instance-1}]" \
#     --associate-public-ip-address \
#     --user-data "$(cat <<'EOF'
# #!/bin/bash
# yum update -y
# yum install -y httpd
# systemctl start httpd
# systemctl enable httpd 
# echo "Hello from Project1 Web Server!" > /var/www/html/index.html
# EOF
#     )" \
#     --query 'Instances[0].InstanceId' --output text)


# echo "Created an EC2 Instance in the first subnet with ID: $INSTANCE1_ID"

# export INSTANCE1_ID

# INSTANCE2_ID=$(aws ec2 run-instances \
#     --image-id $AMI_ID \
#     --instance-type t3.micro \
#     --key-name "Project1-Key" \
#     --security-group-ids $SG_ID \
#     --subnet-id $SEC_PUBLIC_SUBNET_ID \
#     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Project1-Public-Instance-2}]" \
#     --associate-public-ip-address \
#     --user-data "$(cat <<'EOF'
# #!/bin/bash
# yum update -y
# yum install -y httpd
# systemctl start httpd
# systemctl enable httpd 
# echo "Hello from Project1 Web Server!" > /var/www/html/index.html
# EOF
#     )" \
#     --query 'Instances[0].InstanceId' --output text)


# echo "Created a second EC2 Instance in the second subnet with ID: $INSTANCE2_ID"

# export INSTANCE2_ID

# Create a private EC2 instance in the private subnet
PRIVATE_INS1_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --key-name "Project1-Key" \
  --security-group-ids $SG_ID \
  --subnet-id $First_Private_Subnet \
  --no-associate-public-ip-address \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Project1-Private-Instance-1}]" \
  --user-data "$(cat <<'EOF'
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd 
echo "Hello from Project1 Web Server!Subnet A" > /var/www/html/index.html
EOF
    )" \
  --query 'Instances[0].InstanceId' --output text
)

echo "Created a private EC2 Instance in the private subnet with ID: $PRIVATE_INS1_ID"
export PRIVATE_INS1_ID

# Create another private EC2 instance in the other private subnet
PRIVATE_INS2_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --key-name "Project1-Key" \
  --security-group-ids $SG_ID \
  --subnet-id $Second_Private_Subnet \
  --no-associate-public-ip-address \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Project1-Private-Instance-2}]" \
  --user-data "$(cat <<'EOF'
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd 
echo "Hello from Project1 Web Server!Subnet B" > /var/www/html/index.html
EOF
    )" \
  --query 'Instances[0].InstanceId' --output text
)

echo "Created a private EC2 Instance in the private subnet with ID: $PRIVATE_INS2_ID"
export PRIVATE_INS2_ID